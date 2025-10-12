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
    // imemory signals
    logic [DWIDTH - 1:0] addr_i;
    logic [DWIDTH - 1:0] data_i;
    logic write_en;
    logic read_en;
       
    // Fetch signals
    logic [DWIDTH - 1:0] f_pc;
    logic [DWIDTH - 1:0] f_insn;
       
    memory #(
        .AWIDTH(32),
        .DWIDTH(32),
        .BASE_ADDR(32'h01000000)
       ) memory1 (
        .clk(clk),
        .rst(reset),
        .addr_i(f_pc),
        .data_i(data_i),
        .read_en_i(read_en),
        .write_en_i(write_en),
        .data_o(f_insn)
   );
 
    assign read_en = 1'b1;
    assign write_en = 1'b0;

    // Fetch
    fetch #(
        .AWIDTH(32),
        .DWIDTH(32),
        .BASEADDR(32'h01000000)
    ) fetch1 (
        .clk(clk),
        .rst(reset),
        .pc_o(f_pc),            
        .insn_o(f_insn)         
    );

     logic [AWIDTH-1:0] d_pc;
     logic [DWIDTH-1:0] d_insn;
     logic [6:0] d_opcode;
     logic [4:0] d_rd;
     logic [4:0] d_rs1;
     logic [4:0] d_rs2;
     logic [6:0] d_funct7;
     logic [2:0] d_funct3;
     logic [4:0] d_shamt;
     logic [DWIDTH-1:0] d_imm;

decode #(.DWIDTH(DWIDTH), .AWIDTH(AWIDTH)) decode1 (
    .clk (clk),
    .rst (reset),
    .insn_i (f_insn),
    .pc_i (f_pc),

    .pc_o (d_pc),
    .insn_o (f_insn),
    .opcode_o (d_opcode),
    .rd_o (d_rd),
    .rs1_o (d_rs1),
    .rs2_o (d_rs2),
    .funct7_o (d_funct7),
    .funct3_o (d_funct3),
    .shamt_o (d_shamt),
    .imm_o (d_imm)
);

igen #(.DWIDTH(DWIDTH)) igen1 (
    .opcode_i (d_opcode),
    .insn_i (f_insn),
	
    .imm_o (d_imm)
);

logic pcsel_out;
logic immsel_out;
logic regwren_out;
logic rs1sel_out;
logic rs2sel_out;
logic memren_out;
logic memwren_out;
logic [1:0] wbsel_out;
logic [3:0] alusel_out;

control #(.DWIDTH(DWIDTH)) control1 (
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

 /*
  * Instantiate other submodules and
  * probes. To be filled by student...
  *
  */

endmodule : pd2
