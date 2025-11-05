/*
 * Yousif Kndkji
 * Salman Kayani
 * Module: pd4
 *
 * Description: Top level module that will contain sub-module instantiations.
 *
 * Inputs:
 * 1) clk
 * 2) reset signal
 */

`include "constants.svh"

module pd4 #(
    parameter int AWIDTH = 32,
    parameter int DWIDTH = 32
) (
    input logic clk,
    input logic reset
);

	// ---------------------------------------------------------
	// Instruction Memory
	// ---------------------------------------------------------
	// Reads the instruction at the address provided by fetch.
	// The instruction memory is pre-loaded with machine code.

	// imemory signals
	logic [DWIDTH-1:0] addr_i;
	logic [DWIDTH-1:0] data_i;
	logic [DWIDTH-1:0] m_pc;
	logic [DWIDTH-1:0] m_data;
	logic m_address;
	logic m_size_encoded;
	logic write_en;
	logic read_en;

	// Fetch signals
	logic [DWIDTH-1:0] f_pc;
	logic [DWIDTH-1:0] f_insn;

	memory #(
		.AWIDTH(AWIDTH),
		.DWIDTH(DWIDTH),
		.BASE_ADDR(32'h01000000)
	) imemory (
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

	assign m_pc = f_pc;
	assign m_data = f_insn;

	// ---------------------------------------------------------
	// Fetch Stage
	// ---------------------------------------------------------
	// Responsible for maintaining the program counter.
	// On reset, PC is set to BASEADDR. On each clock edge,
	// PC increments by 4 to fetch the next instruction.

	// Fetch
	fetch #(
		.AWIDTH(AWIDTH),
		.DWIDTH(DWIDTH),
		.BASEADDR(32'h01000000)
	) fetch1 (
		.clk(clk),
		.rst(reset),
		.pc_o(f_pc),            
		.insn_o(f_insn)         
	);

	// ---------------------------------------------------------
	// Decode Stage
	// ---------------------------------------------------------
	// Extracts fields such as opcode, rd, rs1, rs2, funct3,
	// and funct7 from the instruction fetched in the previous stage.
	// Also passes along the program counter for use in later stages.

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

	decode #(
		.DWIDTH(DWIDTH),
		.AWIDTH(AWIDTH)
	) decode1 (
		.clk (clk),
		.rst (reset),
		.insn_i (f_insn),
		.pc_i (f_pc),

		.pc_o (d_pc),
		.insn_o (d_insn),
		.opcode_o (d_opcode),
		.rd_o (d_rd),
		.rs1_o (d_rs1),
		.rs2_o (d_rs2),
		.funct7_o (d_funct7),
		.funct3_o (d_funct3),
		.shamt_o (d_shamt),
		.imm_o (d_imm)
	);

	// ---------------------------------------------------------
	// Immediate Generator
	// ---------------------------------------------------------
	// Generates the 32-bit immediate value based on the type
	// of instruction (I-type, S-type, etc.) determined from
	// the opcode field.

	igen #(.DWIDTH(DWIDTH)) igen1 (
		.opcode_i (d_opcode),
		.insn_i (f_insn),

		.imm_o (d_imm)
	);

	// ---------------------------------------------------------
	// Control Path
	// ---------------------------------------------------------
	// Produces the control signals used to steer data between
	// the different stages of the processor. These signals
	// control register file writes, ALU operation, and memory
	// access based on instruction type.

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

	// ---------------------------------------------------------
	// Register File
	// ---------------------------------------------------------

	logic r_write_enable;
	logic [4:0] r_read_rs1;
	logic [4:0] r_read_rs2;
    logic [4:0] r_write_destination;
    logic [DWIDTH-1:0] r_write_data;
	logic [DWIDTH-1:0] r_read_rs1_data;
	logic [DWIDTH-1:0] r_read_rs2_data;

	register_file #(.DWIDTH(DWIDTH)) e_register_file (
		.clk(clk),
		.rst(reset),
		.rs1_i (r_read_rs1),
		.rs2_i (r_read_rs2),
		.rd_i (r_write_destination),
		.datawb_i (r_write_data),
		.regwren_i (r_write_enable),

		.rs1data_o (r_read_rs1_data),
		.rs2data_o (r_read_rs2_data)
	);

	assign r_read_rs1 = d_rs1;
	assign r_read_rs2 = d_rs2;
    assign r_write_destination = d_rd;
    assign r_write_enable = regwren_out;
    assign r_write_data = 0;

	// ---------------------------------------------------------
	// ALU
	// ---------------------------------------------------------

	logic e_br_taken;
	logic [AWIDTH-1:0] e_pc;
	logic [DWIDTH-1:0] e_op1, e_op2, e_alu_res;

	alu #(
		.DWIDTH(DWIDTH), 
		.AWIDTH(AWIDTH)
	) e_alu (
		.pc_i (f_pc),
		.rs1_i (e_op1),
		.rs2_i (e_op2),
		.opcode_i (d_opcode),
		.funct3_i (d_funct3),
		.funct7_i (d_funct7),
		.alusel_i (alusel_out),

		.res_o (e_alu_res),
		.brtaken_o (e_br_taken)
	);

    assign e_op1 = rs1sel_out ? f_pc : r_read_rs1_data;
	assign e_op2 = immsel_out ? d_imm : r_read_rs2_data;

	// ---------------------------------------------------------
	// Branch Control Signals
	// ---------------------------------------------------------

	logic breq_o, brlt_o;

	branch_control #(.DWIDTH(DWIDTH)) branch_ctrl (
		.opcode_i (d_opcode),
		.funct3_i (d_funct3),
		.rs1_i (r_read_rs1_data),
		.rs2_i (r_read_rs2_data),

		.breq_o (breq_o),
		.brlt_o (brlt_o)
	);

	always_comb begin : branch_taken_logic
		e_br_taken = 0;
		if (d_opcode == BTYPE_OPCODE) begin
			unique case (d_funct3)
				BEQ_FUNCT3: e_br_taken = breq_o;
				BNE_FUNCT3: e_br_taken = ~breq_o;
				
				BLT_FUNCT3,
				BLTU_FUNCT3: e_br_taken = brlt_o;
				
				BGE_FUNCT3,
				BGEU_FUNCT3: e_br_taken = ~brlt_o;
				
				default: e_br_taken = 0;
			endcase
		end
	end

	assign e_pc = d_pc;



logic [AWIDTH-1:0] pc_in;
logic [DWIDTH-1:0] alu_res_in;
logic [DWIDTH-1:0] memory_data_in;
logic [1:0] wbsel_in;
logic brtaken_in;
logic w_destination;
logic w_enable;
logic [DWIDTH-1:0] writeback_data_out;
logic [DWIDTH-1:0] w_data;
logic [AWIDTH-1:0] next_pc_out;
logic [AWIDTH-1:0] w_pc;

writeback #(.DWIDTH(DWIDTH), .AWIDTH(AWIDTH)) writeback1 (
      .pc_i (f_pc),
      .alu_res_i (e_alu_res),
      .memory_data_i (f_insn),
      .wbsel_i (wbsel_out),
      .brtaken_i (e_br_taken),

      .writeback_data_o (writeback_data_out),
      .next_pc_o (next_pc_out)
 );

assign w_data = writeback_data_out;
assign w_pc = next_pc_out;
assign w_destination = brtaken_in;
assign w_enable = r_write_enable;

logic [DWIDTH-1:0] data_out;

assign data_out = w_data;


	// program termination logic
	reg is_program = 0;
	always_ff @(posedge clk) begin
		// [TODO] Ask professor if data_out here is f_insn
		if (data_out == 32'h00000073) $finish;  // directly terminate if see ecall
		if (data_out == 32'h00008067) is_program = 1;  // if see ret instruction, it is simple program test
		// [TODO] Change register_file_0.registers[2] to the appropriate x2 register based on your module instantiations...
		if (is_program && (e_register_file.regfile[2] == 32'h01000000 + `MEM_DEPTH)) $finish;
	end

endmodule : pd4
