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
) (
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

	always_comb begin
		// Default control signal values
		pcsel_o = 0;
		immsel_o = 0;
		regwren_o = 0;
		rs1sel_o = 0;
		rs2sel_o = 0;
		memren_o = 0;
		memwren_o = 0;
		wbsel_o = WB_ALU;
		alusel_o = ALU_ADD;


        unique case (opcode_i)

            // =====================================================
            // R-type instructions (ADD, SUB, AND, OR, XOR, SLL, SRL, SRA)
            // =====================================================
            RTYPE_OPCODE: begin
                regwren_o = 1;
                immsel_o  = 0;
                rs1sel_o  = 0;
                rs2sel_o  = 0;
                wbsel_o   = WB_ALU; // ALU result will be written back to register file

                unique case (funct3_i)
                    3'b000: alusel_o = (funct7_i[5]) ? ALU_SUB : ALU_ADD; // SUB or ADD
                    3'b111: alusel_o = ALU_AND;
                    3'b110: alusel_o = ALU_OR;
                    3'b100: alusel_o = ALU_XOR;
                    3'b001: alusel_o = ALU_SLL;
                    3'b101: alusel_o = (funct7_i[5]) ? ALU_SRA : ALU_SRL; // SRA or SRL
                    default: alusel_o = ALU_ADD;
                endcase
            end

            // =====================================================
            // I-type ALU instructions (ADDI, ANDI, ORI, etc.)
            // =====================================================
            ITYPE_OPCODE: begin
                regwren_o = 1;
                immsel_o  = 1;
                rs2sel_o  = 1;
                wbsel_o   = WB_ALU;

                unique case (funct3_i)
                    3'b000: alusel_o = ALU_ADD; // ADDI
                    3'b111: alusel_o = ALU_AND; // ANDI
                    3'b110: alusel_o = ALU_OR; 	// ORI
                    3'b100: alusel_o = ALU_XOR; // XORI
                    3'b001: alusel_o = ALU_SLL; // SLLI
                    3'b101: alusel_o = (funct7_i[5]) ? ALU_SRA : ALU_SRL; // SRAI / SRLI
                    default: alusel_o = ALU_ADD;
                endcase
            end

            // =====================================================
            // Load (LW)
            // =====================================================
            LOAD_OPCODE: begin
                regwren_o = 1;
                immsel_o  = 1;
                memren_o  = 1;
                wbsel_o   = WB_MEM;		// Select memory output for write back
                alusel_o  = ALU_ADD; 	// ALU add base + offset
            end

            // =====================================================
            // Store (SW)
            // =====================================================
            STYPE_OPCODE: begin
                regwren_o = 0;
                immsel_o  = 1;
                memwren_o = 1;
                alusel_o  = ALU_ADD; // ALU add base + offset
            end

            // =====================================================
            // Branch (BEQ, BNE, etc.)
            // =====================================================
            BTYPE_OPCODE: begin
                pcsel_o   = 1;       // Control chooses branch target
                regwren_o = 0;
                immsel_o  = 0;
                alusel_o  = ALU_SUB; // ALU subtract for comparison
            end

            // =====================================================
            // JAL (Jump and Link)
            // =====================================================
            JTYPE_OPCODE: begin
                pcsel_o   = 1;
                regwren_o = 1;
                immsel_o  = 1;
                wbsel_o   = WB_PC; // Write back PC+4 to register file
            end

            // =====================================================
            // LUI
            // =====================================================
            LUI_OPCODE: begin
                regwren_o = 1;
                immsel_o  = 1;
                wbsel_o   = WB_ALU;
                alusel_o  = ALU_PASS; // Pass immediate from ALU
            end
        endcase
    end
	
endmodule : control
