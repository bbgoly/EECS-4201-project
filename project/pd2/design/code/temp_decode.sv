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

    /*
     * Process definitions to be filled by
     * student below...
     */

	assign pc_o = pc_i;
	assign insn_o = insn_i;
	assign opcode_o = insn_i[6:0];

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

    /*
     * Process definitions to be filled by
     * student below...
     */

	assign pc_o = pc_i;
	assign insn_o = insn_i;
	assign opcode_o = insn_i[6:0];
	
// assign shamt_o = 

logic isi_imm, is_stype, is_btype, is_utype, is_jtype;

assign isi_imm = (opcode_o == 7'b0010011) ||
                 (opcode_o == 7'b1100111) ||
                 (opcode_o == 7'b1110011) ||
                 (opcode_o == 7'b0000011);
assign is_stype = (opcode_o == 7'b0100011);
assign is_btype = (opcode_o == 7'b1100011);
assign is_utype = (opcode_o == 7'b0110111) || (opcode_o == 7'b0010111);
assign is_jtype = (opcode_o == 7'b1101111);

always_comb begin
    rd_o     = insn_i[11:7];
    funct3_o = insn_i[14:12];
    rs1_o    = insn_i[19:15];
    rs2_o    = insn_i[24:20];
    funct7_o = insn_i[31:25];
    shamt_o  = insn_i[24:20];

	if (is_stype || is_btype) begin // Add a mask only for specific instruction types that are 5-7 bits wide according to each instruction.
        rd_o     = 5'b0;
        funct7_o = 7'b0;
    end else if (isi_imm) begin
        rs2_o    = 5'b0;
        funct7_o = 7'b0;
    end else if (is_utype || is_jtype) begin
        rs1_o    = 5'b0;
        rs2_o    = 5'b0;
        funct7_o = 7'b0;
    end
end

endmodule : decode
