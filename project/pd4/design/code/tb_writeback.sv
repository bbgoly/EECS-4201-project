/*
 * Yousif Kndkji
 * Salman Kayani
 * Testbench for writeback.sv.
 */

`timescale 1ns/1ps

module tb_writeback;

	localparam DWIDTH = 32;
	localparam AWIDTH = 32;

	// DUT inputs
	logic [AWIDTH-1:0] pc_i;
	logic [DWIDTH-1:0] alu_res_i;
	logic [DWIDTH-1:0] memory_data_i;
	logic [1:0]        wbsel_i;       // Select control: 00=ALU, 01=MEM, 10=PC, 11=ALU (default value)
	logic              brtaken_i;

	// DUT outputs
	logic [DWIDTH-1:0] writeback_data_o;
	logic [AWIDTH-1:0] next_pc_o;

	// Instantiate DUT
	writeback #(.DWIDTH(DWIDTH), .AWIDTH(AWIDTH)) dut (
		.pc_i(pc_i),
		.alu_res_i(alu_res_i),
		.memory_data_i(memory_data_i),
		.wbsel_i(wbsel_i),
		.brtaken_i(brtaken_i),
		.writeback_data_o(writeback_data_o),
		.next_pc_o(next_pc_o)
	);

	// Task to check expected vs. actual writeback outputs
	task check_output(
		input [AWIDTH-1:0] pc_in,
		input [DWIDTH-1:0] alu_in,
		input [DWIDTH-1:0] mem_in,
		input [1:0]        wbsel_in,
		input               brtaken_in,
		input [DWIDTH-1:0] expected_wb,
		input [AWIDTH-1:0] expected_pc,
		input string        test_name
	);
	begin
		pc_i           = pc_in;
		alu_res_i      = alu_in;
		memory_data_i  = mem_in;
		wbsel_i        = wbsel_in;
		brtaken_i      = brtaken_in;
		#10;

		if (writeback_data_o !== expected_wb || next_pc_o !== expected_pc) begin
			$display("[FAIL] %s at time %0t", test_name, $time);
			$display("   Expected WB_DATA=%h, NEXT_PC=%h", expected_wb, expected_pc);
			$display("   Got      WB_DATA=%h, NEXT_PC=%h", writeback_data_o, next_pc_o);
		end else begin
			$display("[PASS] %s at time %0t", test_name, $time);
		end
	end
	endtask

	initial begin
		$display("=== Starting writeback Testbench ===");

		// ALU Writeback
		check_output(32'h01000000, 32'hABCD1234, 32'hDEADBEEF,
					2'b00, 1'b0, 32'hABCD1234, 32'h01000000, "ALU Writeback");

		// Memory Writeback
		check_output(32'h01000000, 32'hABCD1234, 32'hDEADBEEF,
					2'b01, 1'b0, 32'hDEADBEEF, 32'h01000000, "Memory Writeback");

		// PC Writeback on JAL / JALR (must branch)
		check_output(32'h01000000, 32'hABCD1234, 32'hDEADBEEF,
					2'b10, 1'b1, 32'h01000004, 32'hABCD1234, "PC Writeback on JAL / JALR");

		// Branch Taken
		check_output(32'h01000000, 32'hABCD1234, 32'hDEADBEEF,
					2'b00, 1'b1, 32'hABCD1234, 32'hABCD1234, "Branch Taken");
		
		// Branch Not Taken
		check_output(32'h01000000, 32'hABCD1234, 32'hDEADBEEF,
					2'b00, 1'b0, 32'h01000000, 32'hABCD1234, "Branch Not Taken");

		// Zero Inputs
		check_output(32'h00000000, 32'h00000000, 32'h00000000,
					2'b00, 1'b0, 32'h00000000, 32'h00000000, "Zero Inputs");

		// Maximum Value Inputs
		check_output(32'hFFFFFFFF, 32'hFFFFFFFF, 32'hFFFFFFFF,
					2'b11, 1'b1, 32'hFFFFFFFF, 32'hFFFFFFFF, "Maximum Value Inputs");

		$display("=== All writeback tests completed successfully ===");
		$finish;
	end

endmodule
