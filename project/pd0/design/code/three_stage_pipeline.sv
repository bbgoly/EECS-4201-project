import constants_pkg::*;

/*
 * EECS 4201
 * Salman Kayani
 * Yousif Kndkji
 * Module: three_stage_pipeline
 *
 * A 3-stage pipeline (TSP) where the first stage performs an addition of two
 * operands (op1_i, op2_i) and registers the output, and the second stage computes
 * the difference between the output from the first stage and op1_i and registers the
 * output. This means that the output (res_o) must be available two cycles after the
 * corresponding inputs have been observed on the rising clock edge
 *
 * Visually, the circuit should look like this:
 *               <---         Stage 1           --->
 *                                                        <---         Stage 2           --->
 *                                                                                               <--    Stage 3    -->
 *                                    |------------------>|                    |
 * -- op1_i -->|                    | --> |         |     |                    |-->|         |   |                    |
 *             | pipeline registers |     | ALU add | --> | pipeline registers |   | ALU sub |-->| pipeline register  | -- res_o -->
 * -- op2_i -->|                    | --> |         |     |                    |-->|         |   |                    |
 *
 * Inputs:
 * 1) 1-bit clock signal
 * 2) 1-bit wide synchronous reset
 * 3) DWIDTH-wide input op1_i
 * 4) DWIDTH-wide input op2_i
 *
 * Outputs:
 * 1) DWIDTH-wide result res_o
 */

module three_stage_pipeline #(
		parameter int DWIDTH = 8)(
        input logic clk,
        input logic rst,
        input logic [DWIDTH-1:0] op1_i,
        input logic [DWIDTH-1:0] op2_i,
        output logic [DWIDTH-1:0] res_o
	);


	// Stage 1: ALU ADD
	logic [DWIDTH-1:0] s1_res;
	logic [DWIDTH-1:0] s1_reg;

	alu #(.DWIDTH(DWIDTH)) alu_add (
		.sel_i (ADD),
		.op1_i (op1_i),
		.op2_i (op2_i),
		.res_o (s1_res),
		.zero_o(),	// unused
		.neg_o()	// unused
	);

	reg_rst #(.DWIDTH(DWIDTH)) reg_s1 (
		.clk   (clk),
		.rst   (rst),
		.in_i  (s1_res),
		.out_o (s1_reg)
	);

	// Stage 2: ALU SUB
	logic [DWIDTH-1:0] s2_res;
	logic [DWIDTH-1:0] s2_reg;

	alu #(.DWIDTH(DWIDTH)) alu_sub (
		.sel_i (SUB),
		.op1_i (s1_reg),
		.op2_i (op1_i),
		.res_o (s2_res),
		.zero_o(),
		.neg_o()
	);

	reg_rst #(.DWIDTH(DWIDTH)) reg_s2 (
		.clk   (clk),
		.rst   (rst),
		.in_i  (s2_res),
		.out_o (s2_reg)
	);

	// Stage 3: final register
	reg_rst #(.DWIDTH(DWIDTH)) reg_s3 (
		.clk   (clk),
		.rst   (rst),
		.in_i  (s2_reg),
		.out_o (res_o)
	);

endmodule: three_stage_pipeline
