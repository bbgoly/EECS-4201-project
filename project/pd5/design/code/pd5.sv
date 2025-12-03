/*
 * Yousif Kndkji
 * Salman Kayani
 * Module: pd5
 *
 * Description: Top level module that will contain sub-module instantiations.
 *
 * Inputs:
 * 1) clk
 * 2) reset signal
 */

`include "constants.svh"

module pd5 #(
    parameter int AWIDTH = 32,
    parameter int DWIDTH = 32
)(
    input logic clk,
    input logic reset
);

logic [31:0] if_id_pc;
logic [31:0] if_id_insn;
		
	// ---------------------------------------------------------
	// Fetch Stage
	// ---------------------------------------------------------
	// Responsible for maintaining the program counter. On reset,
	// PC is set to BASEADDR. On each clock edge, PC either increments
	// by 4 or jumps to a target PC to fetch the next instruction.

	logic f_pcsel_i; // produced by branch logic and control path
	logic [DWIDTH-1:0] f_pc;
	logic [DWIDTH-1:0] f_insn;
	logic [AWIDTH-1:0] f_target_pc;

	fetch #(
		.AWIDTH(AWIDTH),
		.DWIDTH(DWIDTH),
		.BASEADDR(32'h01000000)
	) fetch1 (
		.clk(clk),
		.rst(reset),
		.pcsel_i(f_pcsel_i),
		.target_pc_i(f_target_pc),
		
		.pc_o(f_pc),            
		.insn_o()         
	);

	// ---------------------------------------------------------
	// Instruction Memory
	// ---------------------------------------------------------
	// Reads the instruction at the address provided by fetch.
	// The read-only instruction memory is pre-loaded with machine code.

	logic [DWIDTH-1:0] m_pc;

	memory #(
		.AWIDTH(AWIDTH),
		.DWIDTH(DWIDTH),
		.BASE_ADDR(32'h01000000)
	) imemory (
		.clk(clk),
		.rst(reset),
		.addr_i(m_pc),
		.data_i(),
		.size_encoded_i(MEM_WORD),
		.read_en_i(1'b1),
		.write_en_i(1'b0),

		.data_o(f_insn)
	);

	assign m_pc = f_pc;

// IF/ID pipeline register 

always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
        if_id_pc   <= 32'b0;
        if_id_insn <= 32'h00000013; // NOP
    end else if (if_flush) begin
        if_id_pc   <= 32'b0;
        if_id_insn <= 32'h00000013;
    end else if (if_id_write) begin
        if_id_pc   <= m_pc;
        if_id_insn <= f_insn;
    end
end

	// ---------------------------------------------------------
	// Decode Stage
	// ---------------------------------------------------------
	// Extracts instruction fields such as opcode, rd, rs1, rs2, funct3,
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

	decode #(
		.DWIDTH(DWIDTH),
		.AWIDTH(AWIDTH)
	) decode1 (
		.clk (clk),
		.rst (reset),
		.insn_i (if_id_insn),
		.pc_i (if_id_pc),

		.pc_o (d_pc),
		.insn_o (d_insn),
		.opcode_o (d_opcode),
		.rd_o (d_rd),
		.rs1_o (d_rs1),
		.rs2_o (d_rs2),
		.funct7_o (d_funct7),
		.funct3_o (d_funct3),
		.shamt_o (d_shamt),
		.imm_o ()
	);

		// ---------------------------------------------------------
	// Immediate Generator
	// ---------------------------------------------------------
	// Generates the 32-bit immediate value based on the type
	// of instruction (I-type, S-type, etc.) determined from
	// the opcode field.
	
	logic [DWIDTH-1:0] d_imm;

	igen #(.DWIDTH(DWIDTH)) igen1 (
		.opcode_i (d_opcode),
		.insn_i (d_insn),

		.imm_o (d_imm)
	);

	
	// ---------------------------------------------------------
	// Control Path
	// ---------------------------------------------------------
	// Produces the control signals used to steer data between
	// the different stages of the core. These signals control
	// register file writes, ALU operation, and memory access 
	// based on instruction type.

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
		.insn_i (d_insn),
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

	logic [31:0] id_ex_pc;
logic [31:0] id_ex_rs1_data;
logic [31:0] id_ex_rs2_data;
logic [31:0] id_ex_imm;
logic [4:0]  id_ex_rs1;
logic [4:0]  id_ex_rs2;
logic [4:0]  id_ex_rd;

logic id_ex_memren;
logic id_ex_regwren;
logic [3:0] id_ex_alusel;

// ID/EX pipeline register

always_ff @(posedge clk or posedge reset) begin
    if (reset || id_ex_flush) begin
        id_ex_memren  <= 1'b0;
        id_ex_regwren <= 1'b0;
        id_ex_alusel  <= 4'b0;
        id_ex_rd      <= 5'b0;
    end else begin
        id_ex_pc        <= if_id_pc;
        id_ex_rs1_data  <= r_read_rs1_data;
        id_ex_rs2_data  <= r_read_rs2_data;
        id_ex_imm       <= d_imm;
        id_ex_rs1       <= d_rs1;
        id_ex_rs2       <= d_rs2;
        id_ex_rd        <= d_rd;

        id_ex_memren    <= memren_out;
        id_ex_regwren   <= regwren_out;
        id_ex_alusel    <= alusel_out;
    end
end

	logic e_br_taken;
	logic [AWIDTH-1:0] e_pc;
	logic [DWIDTH-1:0] e_op1, e_op2, e_alu_res;


	alu #(
		.DWIDTH(DWIDTH), 
		.AWIDTH(AWIDTH)
	) e_alu (
		.pc_i (id_ex_pc),
		.rs1_i (e_op1),
		.rs2_i (e_op2),
		.opcode_i (d_opcode),
		.funct3_i (d_funct3),
		.funct7_i (d_funct7),
		.alusel_i (id_ex_alusel),

		.res_o (e_alu_res),
		.brtaken_o () // produced by branch_taken_logic
	);
	

	assign e_op1 = rs1sel_out ? id_ex_pc : id_ex_rs1_data;
assign e_op2 = immsel_out ? id_ex_imm : id_ex_rs2_data;



	// TODO: Re-create the top-level module from PD4. 
	// Start by defining the pipeline registers between each stage first,
	// then instantiate each stage and connect them together.
	
	// TODO: After pipelining the design, re-visit the fetch stage implementation
	// to re-work how the PC is updated from jumps and branches, since that will
	// no longer be handled in the writeback module.

	// TODO: Order of tasks to complete to achieve a working multi-cycle pipelined design:
	// 1) Pipeline first, and ensure the design works without dependencies (i.e., ensure
	//	  all instructions still work in a pipeline)
	// 2) Create testbenches with no data hazards to verify pipeline correctness
	// 3) Implement stalling, which should probably be determined during decode stage
	//	  and could be implemented in the top-level module
	// 4) Create testbenches with data hazards such as load-use/arithmetic stalls to
	//	  verify stalling correctness
	// 5) Implement data forwarding, probably as muxes in the top-level module
	// 6) Create testbenches with data hazards that can be resolved via forwarding
	//	  to verify forwarding correctness
	// 7) Implement pipeline squashing
	// 8) Create testbenches with control hazards to verify squashing correctness

	// TODO: Remember to update probes.svh with the new probe names, since the names of
	// the probes will likely change during this PD.

	// program termination logic
	reg is_program = 0;
	always_ff @(posedge clk) begin
		// TODO: Termination code pulled directly from PD4, remember to change named registers
		// after pipelining the design, if they were renamed
		if (f_insn == 32'h00000073) $finish;  // directly terminate if see ecall
		if (f_insn == 32'h00008067) is_program = 1;  // if see ret instruction, it is simple program test
		if (is_program && (e_register_file.regfile[2] == 32'h01000000 + `MEM_DEPTH)) $finish;
	end

endmodule : pd5
