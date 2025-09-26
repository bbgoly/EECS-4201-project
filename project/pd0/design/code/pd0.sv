/*
 * EECS 4201
 * Salman Kayani
 * Yousif Kndkji
 * Module: pd0
 *
 * Description: Top level module that will contain sub-module instantiations.
 * An instantiation of the assign_xor module is shown as an example. The other
 * modules must be instantiated similarly. Probes are defined, which will be used
 * to test This file also defines probes that will be used to test the design. Note
 * that the top level module should have only two inputs: clk and rest signals.
 *
 * Inputs:
 * 1) clk
 * 2) reset signal
 */

module pd0 #(
		parameter int DWIDTH = 32)(
		input logic clk,
		input logic reset
	);

	// Probes that will be defined in probes.svh
	logic assign_xor_op1;
	logic assign_xor_op2;
	logic assign_xor_res;

	assign_xor assign_xor_0 (
		.op1_i (assign_xor_op1),
		.op2_i (assign_xor_op2),
		.res_o (assign_xor_res)
	);


	logic [DWIDTH-1:0] alu_op1;
	logic [DWIDTH-1:0] alu_op2;
	logic [DWIDTH-1:0] alu_res;
	logic [1:0] alu_sel;
	logic alu_zero_o;
	logic alu_neg_o;

	alu #(.DWIDTH(DWIDTH)) alu_0 (
		.op1_i (alu_op1),
		.op2_i (alu_op2),
		.res_o (alu_res),
		.sel_i (alu_sel),
		.zero_o (alu_zero_o),
		.neg_o (alu_neg_o)
	);

	logic [DWIDTH-1:0] reg_in;
	logic [DWIDTH-1:0] reg_out;

	reg_rst #(.DWIDTH(DWIDTH)) reg_rst_0 (
		.in_i (reg_in),
		.out_o (reg_out),
		.clk (clk),
		.rst (reset)
	);

	logic [DWIDTH-1:0] tsp_op1;
	logic [DWIDTH-1:0] tsp_op2;
	logic [DWIDTH-1:0] tsp_res;

	three_stage_pipeline #(.DWIDTH(DWIDTH)) three_stage_pipeline_0 (
		.op1_i (tsp_op1),
		.op2_i (tsp_op2),
		.res_o (tsp_res),
		.clk (clk),
		.rst (reset)
	);

endmodule: pd0
