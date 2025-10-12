/*
 * Salman Kayani
 * Module: igen
 *
 * Description: Immediate value generator
 *
 * Inputs:
 * 1) opcode opcode_i
 * 2) input instruction insn_i
 * Outputs:
 * 2) 32-bit immediate value imm_o
 */

module igen #(
    parameter int DWIDTH=32
    )(
    input logic [6:0] opcode_i,
    input logic [DWIDTH-1:0] insn_i,
    output logic [31:0] imm_o
);
    /*
     * Process definitions to be filled by
     * student below...
     */

    always_comb begin
        unique case (opcode_i)
            // I-type (addi, andi, ori, lw, jalr, etc.)
            7'b0010011, // ALU immediate
            7'b0000011, // Load
            7'b1100111: // JALR
                imm_o = {{20{insn_i[31]}}, insn_i[31:20]}; // sign-extend 12-bit imm

            // S-type (store)
            7'b0100011:
                imm_o = {{20{insn_i[31]}}, insn_i[31:25], insn_i[11:7]};

            // B-type (branch)
            7'b1100011:
                imm_o = {{19{insn_i[31]}}, insn_i[31], insn_i[7],
                         insn_i[30:25], insn_i[11:8], 1'b0};

            // U-type (LUI, AUIPC)
            7'b0110111, // LUI
            7'b0010111: // AUIPC
                imm_o = {insn_i[31:12], 12'b0};

            // J-type (JAL)
            7'b1101111:
                imm_o = {{11{insn_i[31]}}, insn_i[31],
                         insn_i[19:12], insn_i[20], insn_i[30:21], 1'b0};

            default:
                imm_o = 32'b0;
        endcase
    end
    
endmodule : igen
