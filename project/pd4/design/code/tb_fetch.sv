/*
 * Yousif Kndkji
 * Testbench for fetch.sv to test PC write-back
 */

`timescale 1ns/1ps

module tb_fetch;

	localparam DWIDTH = 32;
	localparam AWIDTH = 32;
	localparam BASEADDR = 32'h01000000;

	// UUT inputs
	logic clk;
	logic rst;
	logic pcsel_i;
	logic [AWIDTH-1:0] target_pc_i;

	// UUT outputs
	logic [AWIDTH-1:0] pc_o;

	// Fetch UUT
	fetch #(
		.AWIDTH(AWIDTH),
		.DWIDTH(DWIDTH),
		.BASEADDR(BASEADDR)
	) uut_fetch (
		.clk(clk),
		.rst(rst),
		.pcsel_i(pcsel_i),
		.target_pc_i(target_pc_i),

		.pc_o(pc_o),
		.insn_o()
	);

	// Instantiate writeback for testing next_pc_o interaction with fetch

	// Relevant writeback inputs
	logic brtaken_i;
	logic [DWIDTH-1:0] branch_target_i;

	// Writeback UUT
	writeback #(
		.DWIDTH(DWIDTH),
		.AWIDTH(AWIDTH)
	) uut_wb (
		.pc_i(pc_o),
		.alu_res_i(branch_target_i),
		.memory_data_i(),		// unused for this test
		.wbsel_i(2'b10),		// fix write-back to select PC
		.brtaken_i(brtaken_i),

		.writeback_data_o(),	// unused for this test
		.next_pc_o(target_pc_i)
	);

	// Clock generation
	initial clk = 0;
	always #5 clk = ~clk; // 10ns clock period

	task reset_uut;
		rst = 1;
		pcsel_i = 0;
		target_pc_i = 'x;
		repeat (2) @(posedge clk); // hold reset for 2 cycles
		rst = 0;
	endtask

	task test_pc_update(
		input logic pcsel,
		input logic branch_taken,
		input [AWIDTH-1:0] target_pc,
		input [AWIDTH-1:0] expected_pc,
		input string desc
	);
		pcsel_i = pcsel;
		brtaken_i = branch_taken;
		branch_target_i = target_pc;
		
		@(posedge clk);

		if (pc_o !== expected_pc) begin
			$display("TEST FAILED: %s at time %0t\nExpected: %h\nGot: %h", desc, $time, expected_pc, pc_o);
		end else begin
			$display("TEST PASSED: %s at time %0t\nExpected: %h\nPC: %h", desc, $time, expected_pc, pc_o);
		end
	endtask

	initial begin
		$display("== Fetch Test ===");
		
		$dumpfile("tb_fetch.vcd");
		$dumpvars(0, tb_fetch);
		$display("VCD dumped");

		reset_uut();
		$display("UUT module reset");

		// Test 1: PC should be at BASEADDR after reset
		test_pc_update(0, 'x, 'x, BASEADDR, "PC after reset");
		
		// Test 2: PC should increment by 4 when pcsel_i is 0
		test_pc_update(0, 'x, 'x, BASEADDR + 4, "PC increment by 4");

		// Test 3: PC should jump to target_pc_i when pcsel_i is 1 and branch taken
		test_pc_update(1, 1, 32'h01000020, 32'h01000020, "Branch taken, PC jump to target address");

		// Test 4: PC should increment by 4 from target address when pcsel_i is 1 but branch not taken
		// Tests that PC continues to increment by 4 even when pcsel_i is 1 but branch is not taken
		test_pc_update(1, 0, 32'hDEADBEEF, 32'h01000024, "Branch not taken, PC increment by 4 from previous address");

		// Test 5: PC should continue to increment by 4 when pcsel_i is 0
		test_pc_update(0, 'x, 'x, 32'h01000028, "PC increment by 4 from last address");

		// Test 6: PC should jump to target_pc_i when pcsel_i is 1 and branch taken again
		test_pc_update(1, 1, 32'h01000040, 32'h01000040, "Branch taken again, PC jump to new target address");

		$display("=== Fetch Tests Complete ===");
		$finish;
	end

endmodule : tb_fetch