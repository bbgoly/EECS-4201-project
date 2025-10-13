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
            RTYPE_OPCODE: begin
                regwren_o = 1;
                immsel_o  = 0;
                wbsel_o   = WB_ALU; // ALU result will be written back to register file
                rs1sel_o  = 0;
                rs2sel_o  = 0;

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
                wbsel_o   = WB_ALU;
                rs2sel_o  = 1;

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
                wbsel_o   = WB_MEM; // Select memory output for write back
                memren_o  = 1;
                alusel_o  = ALU_ADD; // ALU add base + offset
            end

            // =====================================================
            // Store (SW)
            // =====================================================
            STYPE_OPCODE: begin
                immsel_o  = 1;
                memwren_o = 1;
                regwren_o = 0;
                alusel_o  = ALU_ADD; // ALU add base + offset
            end

            // =====================================================
            // Branch (BEQ, BNE, etc.)
            // =====================================================
            BTYPE_OPCODE: begin
                regwren_o = 0;
                immsel_o  = 0;
                alusel_o  = ALU_SUB; // ALU subtract for comparison
                pcsel_o   = 1;       // control chooses branch target
            end

            // =====================================================
            // JAL (Jump and Link)
            // =====================================================
            JTYPE_OPCODE: begin
                pcsel_o   = 1;
                regwren_o = 1;
                wbsel_o   = WB_PC; // Write back PC+4 to register file
                immsel_o  = 1;
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
