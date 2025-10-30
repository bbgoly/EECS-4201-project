/*
 * Yousif Kndkji
 * Salman Kayani
 * Module: decode
 *
 * Description: Decode stage
 *
 * Inputs:
 * 1) clk
 * 2) rst signal
 * 3) insn_iruction ins_i
 * 4) program counter pc_i
 * Outputs:
 * 1) AWIDTH wide program counter pc_o
 * 2) DWIDTH wide insn_iruction output insn_o
 * 3) 5-bit wide destination register ID rd_o
 * 4) 5-bit wide source 1 register ID rs1_o
 * 5) 5-bit wide source 2 register ID rs2_o
 * 6) 7-bit wide funct7 funct7_o
 * 7) 3-bit wide funct3 funct3_o
 * 8) 32-bit wide immediate imm_o
 * 9) 5-bit wide shift amount shamt_o
 * 10) 7-bit width opcode_o
 */

`include "constants.svh"

module decode #(
    parameter int DWIDTH=32,
    parameter int AWIDTH=32
) (
	// inputs
	input logic clk,
	input logic rst,
	input logic [DWIDTH - 1:0] insn_i,
	input logic [DWIDTH - 1:0] pc_i,

	// outputs
	output logic [AWIDTH-1:0] pc_o,
	output logic [DWIDTH-1:0] insn_o,
	output logic [6:0] opcode_o,
	output logic [4:0] rd_o,
	output logic [4:0] rs1_o,
	output logic [4:0] rs2_o,
	output logic [6:0] funct7_o,
	output logic [2:0] funct3_o,
	output logic [4:0] shamt_o,
	output logic [DWIDTH-1:0] imm_o
);

	assign pc_o = pc_i;
	assign insn_o = insn_i;
	assign opcode_o = insn_i[6:0];

	logic is_itype, is_stype, is_btype, is_utype, is_jtype;

	assign is_itype = (opcode_o == ITYPE_OPCODE) ||
					(opcode_o == SYSTEM_OPCODE) ||
					(opcode_o == JALR_OPCODE) ||
					(opcode_o == LOAD_OPCODE);
	assign is_stype = (opcode_o == STYPE_OPCODE);
	assign is_btype = (opcode_o == BTYPE_OPCODE);
	assign is_utype = (opcode_o == LUI_OPCODE) || (opcode_o == AUIPC_OPCODE);
	assign is_jtype = (opcode_o == JTYPE_OPCODE);

	always_comb begin
		rd_o     = insn_i[11:7];
		funct3_o = insn_i[14:12];
		rs1_o    = insn_i[19:15];
		rs2_o    = insn_i[24:20];
		funct7_o = insn_i[31:25];
		shamt_o  = insn_i[24:20];

		// Clear unused instruction fields based on instruction type
		if (is_stype || is_btype) begin
			// rd_o     = 5'b0;
			// funct7_o = 7'b0;
		end else if (is_itype) begin
			// rs2_o    = 5'b0;
			// funct7_o = 7'b0;
		end else if (is_utype || is_jtype) begin
			rs1_o    = 5'b0;
			rs2_o    = 5'b0;
			funct7_o = 7'b0;
		end
	end

endmodule : decode
