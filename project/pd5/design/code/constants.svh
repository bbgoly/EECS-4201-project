`ifndef CONSTANTS_SVH_
`define CONSTANTS_SVH_

parameter logic [31:0] ZERO = 32'd0;
parameter logic [31:0] NOP = 32'h00000013; // addi x0, x0, 0

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
parameter logic [3:0] ALU_SLT = 4'b1000;
parameter logic [3:0] ALU_SLTU = 4'b1001;
parameter logic [3:0] ALU_PASS = 4'b1010;

// Writeback Select
parameter logic [1:0] WB_ALU = 2'b00;
parameter logic [1:0] WB_MEM = 2'b01;
parameter logic [1:0] WB_PC = 2'b10;

// Branch instruction funct3 codes
parameter logic [2:0] BEQ_FUNCT3 = 3'h0;
parameter logic [2:0] BNE_FUNCT3 = 3'h1;
parameter logic [2:0] BLT_FUNCT3 = 3'h4;
parameter logic [2:0] BGE_FUNCT3 = 3'h5;
parameter logic [2:0] BLTU_FUNCT3 = 3'h6;
parameter logic [2:0] BGEU_FUNCT3 = 3'h7;

// Memory size funct3 codes (load/store share same funct3 for byte/half/word)
parameter logic [2:0] MEM_BYTE = 3'h0;	// LB / SB
parameter logic [2:0] MEM_HALF = 3'h1;	// LH / SH
parameter logic [2:0] MEM_WORD = 3'h2;	// LW / SW
parameter logic [2:0] MEM_LBU = 3'h4;	// LBU
parameter logic [2:0] MEM_LHU = 3'h5;	// LHU

`endif
