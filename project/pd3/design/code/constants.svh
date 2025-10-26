/*
 * Good practice to define constants and refer to them in the
 * design files. An example of some constants are provided to you
 * as a starting point
 *
 */
`ifndef CONSTANTS_SVH_
`define CONSTANTS_SVH_

parameter logic [31:0] ZERO = 32'd0;

// Instruction type opcodes
parameter logic [6:0] RTYPE_OPCODE = 7'b0110011;
parameter logic [6:0] ITYPE_OPCODE = 7'b0010011;
parameter logic [6:0] STYPE_OPCODE = 7'b0100011;
parameter logic [6:0] BTYPE_OPCODE = 7'b1100011;
parameter logic [6:0] JTYPE_OPCODE = 7'b1101111;
parameter logic [6:0] LOAD_OPCODE = 7'b0000011;
parameter logic [6:0] SYSTEM_OPCODE = 7'b1110011;

// Instruction-specific opcodes
parameter logic [6:0] JALR_OPCODE = 7'b1100111;
parameter logic [6:0] LUI_OPCODE = 7'b0110111;
parameter logic [6:0] AUIPC_OPCODE = 7'b0010111;

// ALU Select
parameter logic [3:0] ALU_ADD = 4'b0000;
parameter logic [3:0] ALU_SUB = 4'b0001;
parameter logic [3:0] ALU_AND = 4'b0010;
parameter logic [3:0] ALU_OR = 4'b0011;
parameter logic [3:0] ALU_XOR = 4'b0100;
parameter logic [3:0] ALU_SLL = 4'b0101;
parameter logic [3:0] ALU_SRL = 4'b0110;
parameter logic [3:0] ALU_SRA = 4'b0111;
parameter logic [3:0] ALU_PASS = 4'b1000;

// Writeback Select
parameter logic [1:0] WB_ALU = 2'b00;
parameter logic [1:0] WB_MEM = 2'b01;
parameter logic [1:0] WB_PC = 2'b10;

`endif
