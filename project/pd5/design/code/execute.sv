/*
 * Yousif Kndkji
 * Module: execute
 *
 * Description: ALU implementation for execute stage.
 *
 * Inputs:
 * 1) 32-bit PC pc_i
 * 2) 32-bit rs1 data rs1_i
 * 3) 32-bit rs2 data rs2_i
 * 4) 7-bit opcode opcode_i
 * 5) 3-bit funct3 funct3_i
 * 6) 7-bit funct7 funct7_i
 * 7) 4-bit ALU select alusel_i
 *
 * Outputs:
 * 1) 32-bit result of ALU res_o
 * 2) 1-bit branch taken signal brtaken_o
 */

`include "constants.svh"

module alu #(
    parameter int DWIDTH=32,
    parameter int AWIDTH=32
)(
    input logic [AWIDTH-1:0] pc_i,
    input logic [DWIDTH-1:0] rs1_i,
    input logic [DWIDTH-1:0] rs2_i,
	input logic [6:0] opcode_i,
    input logic [2:0] funct3_i,
    input logic [6:0] funct7_i,
	input logic [3:0] alusel_i,

    output logic [DWIDTH-1:0] res_o,
    output logic brtaken_o
);

	// brtaken_o is computed in top level module using branch_control output instead.
	// We would compute it in this module, but rs1_i and rs2_i are often replaced 
	// by pc and/or an immediate based on control signals

	always_comb begin
		res_o = 0;

		unique case (alusel_i)
			ALU_ADD: res_o = (opcode_i == JALR_OPCODE) 
				? (rs1_i + rs2_i) & 32'hFFFFFFFE
				: rs1_i + rs2_i;
			ALU_SUB: res_o = rs1_i - rs2_i;
			ALU_AND: res_o = rs1_i & rs2_i;
			ALU_OR: res_o = rs1_i | rs2_i;
			ALU_XOR: res_o = rs1_i ^ rs2_i;
			ALU_SLL: res_o = rs1_i << rs2_i[4:0];
			ALU_SRL: res_o = rs1_i >> rs2_i[4:0];
			ALU_SRA: res_o = rs1_i >>> rs2_i[4:0];
            ALU_SLT: res_o = signed'(rs1_i) < signed'(rs2_i);
            ALU_SLTU: res_o = rs1_i < rs2_i;
			ALU_PASS: res_o = rs2_i;
		endcase
	end

endmodule : alu
