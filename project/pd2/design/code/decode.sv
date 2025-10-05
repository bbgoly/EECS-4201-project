/*
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
)(
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

/* Pseudocode for implementation
module decode:
  inputs:
    clk, rst
    insn_i [31:0]
    pc_i   [AWIDTH-1:0]

  outputs:
    pc_o     <= AWIDTH bits
    insn_o   <= 32 bits
    opcode_o <= insn_i[6:0]
    rd_o     <= insn_i[11:7]
    funct3_o <= insn_i[14:12]
    rs1_o    <= insn_i[19:15]
    rs2_o    <= insn_i[24:20]
    funct7_o <= insn_i[31:25]
    shamt_o  <= insn_i[24:20]    // shift amount for shift-immediate operations
    imm_o    <= 32-bit sign-extended immediate (see below)

  combinational helper: Produce an immediate instruction based on its opcode 
  imm_from_inst(inst):
	return immediate instruction

  synchronous process for reset:
    always_ff @(posedge clk or posedge rst)
	
*/



	
    /*
     * Process definitions to be filled by
     * student below...
     */

endmodule : decode


