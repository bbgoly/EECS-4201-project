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

always_comb begin

        unique case (opcode_i)

            // =====================================================
            // R-type instructions (ADD, SUB, AND, OR, XOR, SLL, SRL, SRA)
            // =====================================================
            7'b0110011: begin
                regwren_o = 1;
                immsel_o  = 0;
                wbsel_o   = 2'b00; // ALU result
                rs1sel_o  = 0;
                rs2sel_o  = 0;

                unique case (funct3_i)
                    3'b000: alusel_o = (funct7_i[5]) ? 4'b0001 : 4'b0000; // SUB or ADD
                    3'b111: alusel_o = 4'b0010; // AND
                    3'b110: alusel_o = 4'b0011; // OR
                    3'b100: alusel_o = 4'b0100; // XOR
                    3'b001: alusel_o = 4'b0101; // SLL
                    3'b101: alusel_o = (funct7_i[5]) ? 4'b0111 : 4'b0110; // SRA or SRL
                    default: alusel_o = 4'b0000;
                endcase
            end

            // =====================================================
            // I-type ALU instructions (ADDI, ANDI, ORI, etc.)
            // =====================================================
            7'b0010011: begin
                regwren_o = 1;
                immsel_o  = 1;
                wbsel_o   = 2'b00;
                rs2sel_o  = 1;

                unique case (funct3_i)
                    3'b000: alusel_o = 4'b0000; // ADDI
                    3'b111: alusel_o = 4'b0010; // ANDI
                    3'b110: alusel_o = 4'b0011; // ORI
                    3'b100: alusel_o = 4'b0100; // XORI
                    3'b001: alusel_o = 4'b0101; // SLLI
                    3'b101: alusel_o = (funct7_i[5]) ? 4'b0111 : 4'b0110; // SRAI / SRLI
                    default: alusel_o = 4'b0000;
                endcase
            end

            // =====================================================
            // Load (LW)
            // =====================================================
            7'b0000011: begin
                regwren_o = 1;
                immsel_o  = 1;
                wbsel_o   = 2'b01; // Memory data
                memren_o  = 1;
                alusel_o  = 4'b0000; // ADD base + offset
            end

            // =====================================================
            // Store (SW)
            // =====================================================
            7'b0100011: begin
                immsel_o  = 1;
                memwren_o = 1;
                regwren_o = 0;
                alusel_o  = 4'b0000; // ADD base + offset
            end

            // =====================================================
            // Branch (BEQ, BNE, etc.)
            // =====================================================
            7'b1100011: begin
                regwren_o = 0;
                immsel_o  = 0;
                alusel_o  = 4'b0001; // SUB for comparison
                pcsel_o   = 1;       // control chooses branch target
            end

            // =====================================================
            // JAL (Jump and Link)
            // =====================================================
            7'b1101111: begin
                pcsel_o   = 1;
                regwren_o = 1;
                wbsel_o   = 2'b10; // PC+4
                immsel_o  = 1;
            end

            // =====================================================
            // LUI
            // =====================================================
            7'b0110111: begin
                regwren_o = 1;
                immsel_o  = 1;
                wbsel_o   = 2'b00;
                alusel_o  = 4'b1000; // Pass immediate
            end
        endcase
    end
endmodule : control
