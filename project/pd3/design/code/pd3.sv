/*
 * Yousif Kndkji
 * Salman Kayani
 * Module: pd3
 *
 * Description: Top level module that will contain sub-module instantiations.
 *
 * Inputs:
 * 1) clk
 * 2) reset signal
 */

module pd3 #(
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
	logic [DWIDTH - 1:0] addr_i;
	logic [DWIDTH - 1:0] data_i;
	logic write_en;
	logic read_en;
		
	// Fetch signals
	logic [DWIDTH - 1:0] f_pc;
	logic [DWIDTH - 1:0] f_insn;
		
	memory #(
		.AWIDTH(AWIDTH),
		.DWIDTH(DWIDTH),
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

	logic [DWIDTH-1:0] wb_data; // see writeback mux below, only for testing this pd

	logic r_write_enable;
	logic [4:0] r_read_rs1;
	logic [4:0] r_read_rs2;
	logic [DWIDTH-1:0] r_read_rs1_data;
	logic [DWIDTH-1:0] r_read_rs2_data;

	register_file #(.DWIDTH(DWIDTH)) e_register_file (
		.clk(clk),
		.rst(reset),
		.rs1_i (d_rs1),
		.rs2_i (d_rs2),
		.rd_i (d_rd),
		.datawb_i (wb_data),
		.regwren_i (regwren_out),

		.rs1data_o (r_read_rs1_data),
		.rs2data_o (r_read_rs2_data)
	);

	assign r_read_rs1 = d_rs1;
	assign r_read_rs2 = d_rs2;

	// ---------------------------------------------------------
	// ALU
	// ---------------------------------------------------------

	logic e_br_taken;
	logic [AWIDTH-1:0] e_pc;
	logic [DWIDTH-1:0] e_op2, e_alu_res;

	alu #(
		.DWIDTH(DWIDTH), 
		.AWIDTH(AWIDTH)
	) e_alu (
		.pc_i (f_pc),
		.rs1_i (r_read_rs1_data),
		.rs2_i (e_op2),
		.opcode_i (d_opcode),
		.funct3_i (d_funct3),
		.funct7_i (d_funct7),
		.alusel_i (alusel_out),

		.res_o (e_alu_res),
		.brtaken_o (e_br_taken)
	);

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

	assign e_pc = d_pc;
	assign e_br_taken = breq_o | brlt_o;

	// ---------------------------------------------------------
	// Writeback Multiplexer 
	// (very basic implementation for the sole purpose of testing 
	// the register file, despite this PD not implementing write-back)
	// ---------------------------------------------------------

	logic [DWIDTH-1:0] pc_plus4;

	assign pc_plus4 = f_pc + 32'd4;

	always_comb begin
		unique case (wbsel_out)
			2'b00: wb_data = e_alu_res;
			2'b01: wb_data = f_insn;
			2'b10: wb_data = e_br_taken ? e_alu_res : pc_plus4;
			default: wb_data = '0;
		endcase
	end

endmodule : pd3