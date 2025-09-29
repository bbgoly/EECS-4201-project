/*
 * Module: pd2
 *
 * Description: Top level module that will contain sub-module instantiations.
 *
 * Inputs:
 * 1) clk
 * 2) reset signal
 */

module pd2 #(
    parameter int AWIDTH = 32,
    parameter int DWIDTH = 32)(
    input logic clk,
    input logic reset
);


logic [AWIDTH-1:0] addr;
logic [DWIDTH-1:0] data_in;
logic read_en;
logic write_en;
logic [DWIDTH-1:0] data_out;

memory #(.AWIDTH(AWIDTH), .DWIDTH(DWIDTH)) memory_0 (
  .clk (clk),
  .rst (reset),
  .addr_i (addr),
  .data_i (data_in),
  .read_en_i (read_en),
  .write_en_i (write_en),
  .data_o (data_out)
);


logic [AWIDTH - 1:0] f_pc;
logic [DWIDTH - 1:0] f_insn;

fetch #(.AWIDTH(AWIDTH), .DWIDTH(DWIDTH)) fetch_0 (
  .clk (clk),
  .rst (reset),
  .pc_o (f_pc),
  .insn_o (f_insn)
);


//logic [DWIDTH-1:0] d_imm;
     //logic [DWIDTH - 1:0] insn_in;
     //logic [DWIDTH - 1:0] pc_in;
     logic [AWIDTH-1:0] d_pc;
     logic [DWIDTH-1:0] insn_out;
     logic [6:0] d_opcode;
     logic [4:0] d_rd;
     logic [4:0] d_rs1;
     logic [4:0] d_rs2;
     logic [6:0] d_funct7;
     logic [2:0] d_funct3;
     logic [4:0] d_shamt;
     logic [DWIDTH-1:0] d_imm;

decode #(.DWIDTH(DWIDTH), .AWIDTH(AWIDTH)) decode_0 (

    .clk (clk),
    .rst (reset),
    .insn_i (f_insn),
    .pc_i (f_pc),

    .pc_o (d_pc),
    .insn_o (insn_out),
    .opcode_o (d_opcode),
    .rd_o (d_rd),
    .rs1_o (d_rs1),
    .rs2_o (d_rs2),
    .funct7_o (d_funct7),
    .funct3_o (d_funct3),
    .shamt_o (d_shamt),
    .imm_o (d_imm)
);

//logic [DWIDTH - 1:0] f_insn;
//logic [6:0] d_opcode;
//logic [6:0] d_funct7;
//logic [2:0] d_funct3;
logic pcsel_out;
logic immsel_out;
logic regwren_out;
logic rs1sel_out;
logic rs2sel_out;
logic memren_out;
logic memwren_out;
logic [1:0] wbsel_out;
logic [3:0] alusel_out;

control #(.DWIDTH(DWIDTH)) control_0 (
    .insn_i (f_insn),
    .opcode_i (d_opcode),
    .funct7_i (d_funct7),
    .funct3_i (d_funct3),

    .pcsel_o (pcsel_out),
    .immsel_o (immsel_out),
    .regwren_o (regwren_out),
    .rs1sel_o (rs1sel_out),
    .rs2sel_o (rs2sel_out),
    .memren_o (memren_out),
    .memwren_o (memwren_out),
    .wbsel_o (wbsel_out),
    .alusel_o (alusel_out)
);



/**decode #(.DWIDTH(DWIDTH), .AWIDTH(AWIDTH)) decode_0 (

  	.clk (clk),
  	.rst (reset),
	.insn_i (insn_in),
	.pc_i (pc_in),

    .pc_o (pc_out),
    .insn_o (insn_out),
    .opcode_o (opcode_out),
    .rd_o (rd_out),
    .rs1_o (rs1_out),
    .rs2_o (rs2_out),
    .funct7_o (funct7_out),
    .funct3_o (funct3_out),
    .shamt_o (shamt_out),
    .imm_o (imm_out)
);
**/
logic [DWIDTH-1:0] imm_out_1;
igen igen_0 (
    .opcode_i (d_opcode),

    .imm_o (imm_out_1)
);

 /*
  * Instantiate other submodules and
  * probes. To be filled by student...
  *
  */

endmodule : pd2
