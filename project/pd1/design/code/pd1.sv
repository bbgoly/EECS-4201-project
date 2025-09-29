/* Salman Kayani
 * Yousif Kndkji
 * Module: pd1
 *
 * Description: Top level module that will contain sub-module instantiations.
 *
 * Inputs:
 * 1) clk
 * 2) reset signal
 */

module pd1 #(
		parameter int AWIDTH = 32,
		parameter int DWIDTH = 32)(
		input logic clk,
		input logic reset
	);

	logic [AWIDTH-1:0] addr;
	logic [DWIDTH-1:0] data_in;
	logic read_en;
	logic write_en;
	logic [DWIDTH-1:0] data_out;

	memory #(.AWIDTH(AWIDTH), .DWIDTH(DWIDTH)) memory_0 (
		.clk (clk),
		.rst (reset),
		.addr_i (addr),
		.data_i (data_in),
		.read_en_i (read_en),
		.write_en_i (write_en),
		.data_o (data_out)
	);

	logic [AWIDTH - 1:0] f_pc;
	logic [DWIDTH - 1:0] f_insn;

	fetch #(.AWIDTH(AWIDTH), .DWIDTH(DWIDTH)) fetch_0 (
		.clk (clk),
		.rst (reset),
		.pc_o (f_pc),
		.insn_o (f_insn)
	);

endmodule : pd1
