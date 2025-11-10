/*
 * Yousif Kndkji
 * Testbench for memory.sv
 */

`timescale 1ns/1ps

`include "constants.svh"

module tb_memory;

	localparam DWIDTH = 32;
	localparam AWIDTH = 32;
	localparam BASE_ADDR = 32'h01000000;

	// UUT inputs
	logic clk;
	logic rst;
	logic [AWIDTH-1:0] addr_i;
	logic [DWIDTH-1:0] data_i;
	logic [2:0] size_encoded_i;
	logic read_en_i;
	logic write_en_i;

	// UUT outputs
	logic [DWIDTH-1:0] data_o;

	// Instantiate UUT
	memory #(
		.AWIDTH(AWIDTH), 
		.DWIDTH(DWIDTH), 
		.BASE_ADDR(BASE_ADDR)
	) uut (
		.clk(clk),
		.rst(rst),
		.addr_i(addr_i),
		.data_i(data_i),
		.size_encoded_i(size_encoded_i),
		.read_en_i(read_en_i),
		.write_en_i(write_en_i),

		.data_o(data_o)
	);

	// Clock generation
	initial clk = 0;
	always #5 clk = ~clk; // 10ns clock period

	// Reset UUT
	task reset_uut;
		rst = 1;
		addr_i = BASE_ADDR;
		data_i = 'x;
		size_encoded_i = 'x;
		read_en_i = 0;
		write_en_i = 0;
		#15;
		rst = 0;
		#10;
	endtask : reset_uut

	// Write task
	task write_memory(
		input [AWIDTH-1:0] address,
		input [DWIDTH-1:0] data,
		input [2:0] size_encoded
	);
		@(posedge clk);
		addr_i = address;
		data_i = data;
		size_encoded_i = size_encoded;
		write_en_i = 1;
		read_en_i = 0;
		@(posedge clk);
		write_en_i = 0;
		data_i = 'x;
		size_encoded_i = 'x;
		#1;
	endtask : write_memory

	// Read task
	task read_memory(
		input [AWIDTH-1:0] address,
		input [2:0] size_encoded
	);
		@(posedge clk);
		addr_i = address;
		size_encoded_i = size_encoded;
		write_en_i = 0;
		read_en_i = 1;
		#1;
		read_en_i = 0;
		size_encoded_i = 'x;
		addr_i = 'x;
		#1;
	endtask : read_memory

	task check_output(
		input [DWIDTH-1:0] value,
		input [DWIDTH-1:0] expected,
		input string desc
	);
		if (value !== expected)
			$display("TEST FAILED: %s at time %0t\nExpected: %h\nGot: %h", desc, $time, expected, value);
		else
			$display("TEST PASSED: %s at time %0t\nData: %h\nDecimal: %d", desc, $time, value, value);
	endtask : check_output

	initial begin
		$display("=== Memory Test ===");
		$display("Memory dumped from %s", `MEM_PATH);

		$dumpfile("tb_memory.vcd");
		$dumpvars(0, tb_memory);
		$display("VCD dumped");

		reset_uut();
		$display("UUT module reset");

		$display("Begin memory tests...");

		// Test 1: Read first instruction (from test1.x)
		read_memory(BASE_ADDR, 'x);
		check_output(data_o, 32'hfd010113, "read first instruction at base address");

		// Test 2: Write word, then read it
		write_memory(BASE_ADDR, 32'hDEADBEEF, MEM_WORD);
		read_memory(BASE_ADDR, MEM_WORD);
		check_output(data_o, 32'hDEADBEEF, "store DEADBEEF at base address (sw), then read it (lw)");

		// Test 3: Write half-word, then read it
		write_memory(BASE_ADDR + 4, 32'h0000BEEF, MEM_HALF);
		read_memory(BASE_ADDR + 4, MEM_HALF);
		check_output(data_o, 32'h0000BEEF, "store BEEF at base address + 4 (sh), then read it (lh)");

		// Test 4: Write byte, then read it
		write_memory(BASE_ADDR + 8, 32'h000000EF, MEM_BYTE);
		read_memory(BASE_ADDR + 8, MEM_BYTE);
		check_output(data_o, 32'h000000EF, "store EF at base address + 8 (sb), then read it (lb)");

		// Test 5: Write half-byte, then read it unsigned
		write_memory(BASE_ADDR + 12, 32'h0000BEEF, MEM_HALF);
		read_memory(BASE_ADDR + 12, MEM_LHU);
		check_output(data_o, 32'h0000BEEF, "store BEEF at base address + 12 (sh), then read it (lhu)");

		// Test 6: Write byte, then read it unsigned
		write_memory(BASE_ADDR + 16, 32'h000000EF, MEM_BYTE);
		read_memory(BASE_ADDR + 16, MEM_LBU);
		check_output(data_o, 32'h000000EF, "store EF at base address + 16 (sb), then read it (lbu)");

		// Test 6: Write -80, then read it
		write_memory(BASE_ADDR + 20, 32'hFFFFFFB0, MEM_BYTE);
		read_memory(BASE_ADDR + 20, MEM_BYTE);
		check_output(data_o, 32'hFFFFFF80, "store -80 at base address + 20 (sb), then read it (lb)");

		$display("=== Memory Tests Complete ===");
		$finish;
	end

endmodule : tb_memory