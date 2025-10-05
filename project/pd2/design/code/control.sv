/*
 * Module: control
 *
 * Description: This module sets the control bits (control path) based on the decoded
 * instruction. Note that this is part of the decode stage but housed in a separate
 * module for better readability, debug and design purposes.
 *
 * Inputs:
 * 1) DWIDTH instruction ins_i
 * 2) 7-bit opcode opcode_i
 * 3) 7-bit funct7 funct7_i
 * 4) 3-bit funct3 funct3_i
 *
 * Outputs:
 * 1) 1-bit PC select pcsel_o
 * 2) 1-bit Immediate select immsel_o
 * 3) 1-bit register write en regwren_o
 * 4) 1-bit rs1 select rs1sel_o
 * 5) 1-bit rs2 select rs2sel_o
 * 6) k-bit ALU select alusel_o
 * 7) 1-bit memory read en memren_o
 * 8) 1-bit memory write en memwren_o
 * 9) 2-bit writeback sel wbsel_o
 */

`include "constants.svh"

module control #(
	parameter int DWIDTH=32
)(
	// inputs
    input logic [DWIDTH-1:0] insn_i,
    input logic [6:0] opcode_i,
    input logic [6:0] funct7_i,
    input logic [2:0] funct3_i,

    // outputs
    output logic pcsel_o,
    output logic immsel_o,
    output logic regwren_o,
    output logic rs1sel_o,
    output logic rs2sel_o,
    output logic memren_o,
    output logic memwren_o,
    output logic [1:0] wbsel_o,
    output logic [3:0] alusel_o
);


/* Pseudocode for implementation
  define ALU opcodes:
    ALU_ADD
    ALU_SUB
    ALU_SLL
    ALU_SLT
    ALU_SLTU
    ALU_XOR
    ALU_SRL
    ALU_SRA
    ALU_OR
    ALU_AN
    ALU_PASS

  // Select behavior by opcode
  switch (opcode_i)

    case LOAD (7'b0000011):

    case STORE (7'b0100011):

    case BRANCH (7'b1100011):

    case JAL (7'b1101111):

    case JALR (7'b1100111):

    case LUI (7'b0110111):

    case AUIPC (7'b0010111):

    case ALU_IMM (7'b0010011):

    case ALU_REG (7'b0110011):

    default:
      // leave defaults (all zeros)

  end switch
  // Helper: decode_alu_op(funct3, funct7, is_imm)
*/

    /*
     * Process definitions to be filled by
     * student below...
     */

endmodule : control

