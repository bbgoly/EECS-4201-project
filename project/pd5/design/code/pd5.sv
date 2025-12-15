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
	// ---------------------------------------------------------
	// Pipeline Registers
	// ---------------------------------------------------------

	// IF/ID pipeline registers
	logic [AWIDTH-1:0] if_id_pc;
	logic [DWIDTH-1:0] if_id_insn;

	// ID/EX pipeline registers
	logic [AWIDTH-1:0] id_ex_pc;

	// Decoded instruction fields
	logic [6:0] id_ex_opcode;
	logic [4:0] id_ex_rd;
	logic [4:0] id_ex_rs1;
	logic [4:0] id_ex_rs2;
	logic [2:0] id_ex_funct3;
	logic [6:0] id_ex_funct7;
	logic [DWIDTH-1:0] id_ex_imm;

	// Control signals
	logic id_ex_pcsel;
	logic id_ex_immsel;
	logic id_ex_regwren;
	logic id_ex_rs1sel;
	logic id_ex_rs2sel;
	logic id_ex_memren;
	logic id_ex_memwren;
	logic [1:0] id_ex_wbsel;
	logic [3:0] id_ex_alusel;

	// Register file outputs
	logic [DWIDTH-1:0] id_ex_rs1_data;
	logic [DWIDTH-1:0] id_ex_rs2_data;

	// EX/MEM pipeline registers
	logic [AWIDTH-1:0] ex_mem_pc;
	logic [DWIDTH-1:0] ex_mem_rs2_data; // Only rs2 data is needed past EX stage for stores
	logic [6:0] ex_mem_opcode; 			// Opcode and funct3 purpose in memory stage described below
	logic [4:0] ex_mem_rd;
	logic [4:0] ex_mem_rs2;
	logic [2:0] ex_mem_funct3;

	// Control signals
	logic ex_mem_regwren;
	logic ex_mem_memren;
	logic ex_mem_memwren;
	logic [1:0] ex_mem_wbsel;

	// ALU output
	logic [DWIDTH-1:0] ex_mem_alu_res;

	// MEM/WB pipeline registers
	logic [AWIDTH-1:0] mem_wb_pc;
	logic [DWIDTH-1:0] mem_wb_alu_res;
	logic [4:0] mem_wb_rd;

	// Control signals
	logic mem_wb_regwren;
	logic [1:0] mem_wb_wbsel;

	// Data memory output
	logic [DWIDTH-1:0] mem_wb_mem_data;

	// ---------------------------------------------------------
	// Stall Hazard Detection Signals
	// ---------------------------------------------------------

	// Write-decode hazard stall enable signal
	logic wd_stall_en;

	// Load-use hazard stall enable signal
	logic load_use_stall_en;

	// ---------------------------------------------------------
	// Fetch Stage
	// ---------------------------------------------------------
	// Responsible for maintaining the program counter. On reset,
	// PC is set to BASEADDR. On each clock edge, PC either increments
	// by 4 or jumps to a target PC to fetch the next instruction.

	// Stall enable signal, produced in ID stage
	logic stall_en;

	logic f_pcsel_i; // produced by branch logic and control path
	logic [AWIDTH-1:0] f_pc;
	logic [AWIDTH-1:0] f_target_pc;

	fetch #(
		.AWIDTH(AWIDTH),
		.DWIDTH(DWIDTH),
		.BASEADDR(32'h01000000)
	) ifetch (
		.clk(clk),
		.rst(reset),
		.pcsel_i(f_pcsel_i),
		.target_pc_i(f_target_pc),
		.stall_en_i(stall_en),
		
		.pc_o(f_pc),
		.insn_o()
	);

	// ---------------------------------------------------------
	// Instruction Memory
	// ---------------------------------------------------------
	// Reads the instruction at the address provided by fetch.
	// The read-only instruction memory is pre-loaded with machine code.

	logic [DWIDTH-1:0] f_insn;

	memory #(
		.AWIDTH(AWIDTH),
		.DWIDTH(DWIDTH),
		.BASE_ADDR(32'h01000000)
	) imemory (
		.clk(clk),
		.rst(reset),
		.addr_i(f_pc),
		.data_i(),
		.size_encoded_i(MEM_WORD),
		.read_en_i(1'b1),
		.write_en_i(1'b0),

		.data_o(f_insn)
	);
	
	// IF/ID pipeline register logic
	always_ff @(posedge clk or posedge reset) begin : if_id_pipeline_reg
		if (reset) begin
			if_id_pc   <= 32'b0;
			if_id_insn <= 32'b0;
		end else if (f_pcsel_i && !wd_stall_en) begin
			// Squash instructions fetched before branch resolved by inserting NOP
			// if_id_pc   <= 32'b0; // PC is not cleared on branch squash to satisfy tests
			if_id_insn <= NOP; // NOP implemented as addi x0, x0, 0
		end else if (!stall_en) begin
			// Freeze IF/ID registers on load-use hazard or WD stall, 
			// otherwise update them with new instruction and PC
			if_id_pc   <= f_pc;
			if_id_insn <= f_insn;
		end
	end

	// IF/ID pipeline register logic
	// always_ff @(posedge clk or posedge reset) begin : if_id_pipeline_reg
	// 	if (reset) begin
	// 		if_id_pc   <= 32'b0;
	// 		if_id_insn <= 32'b0;
	// 	end else if (stall_en) begin
	// 		// Freeze IF/ID registers on load-use hazard or WD stall, 
	// 		if_id_pc   <= if_id_pc;
	// 		if_id_insn <= if_id_insn;
	// 	end else if (f_pcsel_i) begin
	// 		// Squash instructions fetched before branch resolved by inserting NOP
	// 		// if_id_pc   <= 32'b0; // PC is not cleared on branch squash to satisfy tests
	// 		if_id_insn <= NOP; // NOP implemented as addi x0, x0, 0
	// 	end else begin
	// 		// Update IF/ID registers with new instruction and PC
	// 		if_id_pc   <= f_pc;
	// 		if_id_insn <= f_insn;
	// 	end
	// end

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
	) idecode (
		.clk (clk),
		.rst (reset),
		.pc_i (if_id_pc),
		.insn_i (if_id_insn),

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

	igen #(.DWIDTH(DWIDTH)) imm_gen (
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

	logic pcsel_o;
	logic immsel_o;
	logic regwren_o;
	logic rs1sel_o;
	logic rs2sel_o;
	logic memren_o;
	logic memwren_o;
	logic [1:0] wbsel_o;
	logic [3:0] alusel_o;

	control #(.DWIDTH(DWIDTH)) ctrl (
		.insn_i (d_insn),
		.opcode_i (d_opcode),
		.funct7_i (d_funct7),
		.funct3_i (d_funct3),

		.pcsel_o (pcsel_o),
		.immsel_o (immsel_o),
		.regwren_o (regwren_o),
		.rs1sel_o (rs1sel_o),
		.rs2sel_o (rs2sel_o),
		.memren_o (memren_o),
		.memwren_o (memwren_o),
		.wbsel_o (wbsel_o),
		.alusel_o (alusel_o)
	);

	// Stall hazard detection logic

	// For both stalls, rd must equal either rs1 or rs2, so 
	// checking rd != x0 is equivalent to (rs1 != x0 || rs2 != x0)

	// rd != x0 && (rd == rs1 || rd == rs2) ⇒ (rs1 != x0) || (rs2 != x0)
	// Therefore, for both stalls, we only need to check LHS condition

	// Write-decode hazard stall logic
	assign wd_stall_en = mem_wb_regwren &&
		mem_wb_rd != 5'b0 && (
			(rs1sel_o && mem_wb_rd == d_rs1) || 
			(rs2sel_o && mem_wb_rd == d_rs2)
		);

	// Load-use hazard stall logic
	assign load_use_stall_en = id_ex_memren && 
		id_ex_rd != 5'b0 && (
			id_ex_rd == d_rs1 ||
			(id_ex_rd == d_rs2 && !memwren_o) // do not stall store instructions (can use W/M bypass)
		);
		
	assign stall_en = wd_stall_en | load_use_stall_en;
	
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

	register_file #(.DWIDTH(DWIDTH)) rf (
		.clk(clk),
		.rst(reset),
		.rs1_i (r_read_rs1),
		.rs2_i (r_read_rs2),
		.rd_i (mem_wb_rd),
		.datawb_i (r_write_data),		// Produced by writeback stage (MEM/WB)
		.regwren_i (mem_wb_regwren),	// Register file is written to in writeback stage

		.rs1data_o (r_read_rs1_data),
		.rs2data_o (r_read_rs2_data)
	);

	// Probe assignments
	assign r_read_rs1 = d_rs1;
	assign r_read_rs2 = d_rs2;
    assign r_write_destination = d_rd;
    assign r_write_enable = regwren_o;

	// ID/EX pipeline register logic
	always_ff @(posedge clk or posedge reset) begin : id_ex_pipeline_reg
		if (reset || stall_en) begin
			// Insert bubble into ID/EX on load-use or WD hazard stall
			id_ex_pc <= 32'b0;

			id_ex_opcode <= 7'b0;
			id_ex_rd <= 5'b0;
			id_ex_rs1 <= 5'b0;
			id_ex_rs2 <= 5'b0;
			id_ex_funct3 <= 3'b0;
			id_ex_funct7 <= 7'b0;
			id_ex_imm <= 32'b0;

			id_ex_rs1_data <= 32'b0;
			id_ex_rs2_data <= 32'b0;
		end else if (f_pcsel_i) begin
			// Squash ID/EX due to branch taken
			id_ex_pc <= if_id_pc;

			id_ex_opcode <= 7'b0;
			id_ex_rd <= 5'b0;
			id_ex_rs1 <= 5'b0;
			id_ex_rs2 <= 5'b0;
			id_ex_funct3 <= 3'b0;
			id_ex_funct7 <= 7'b0;
			id_ex_imm <= 32'b0;
		end else begin
			id_ex_pc <= if_id_pc;

			id_ex_opcode <= d_opcode;
			id_ex_rd <= d_rd;
			id_ex_rs1 <= d_rs1;
			id_ex_rs2 <= d_rs2;
			id_ex_funct3 <= d_funct3;
			id_ex_funct7 <= d_funct7;
			id_ex_imm <= d_imm;

			id_ex_rs1_data <= r_read_rs1_data;
			id_ex_rs2_data <= r_read_rs2_data;
		end
	end

	always_ff @(posedge clk or posedge reset) begin : id_ex_control_pipeline_reg
		if (reset || stall_en) begin // || f_pcsel_i might not be needed due to NOP insertion
			// Flush control signals on load-use or WD hazard stall
			id_ex_pcsel <= 1'b0;
			id_ex_immsel <= 1'b0;
			id_ex_regwren <= 1'b0;
			id_ex_rs1sel <= 1'b0;
			id_ex_rs2sel <= 1'b0;
			id_ex_memren <= 1'b0;
			id_ex_memwren <= 1'b0;
			id_ex_wbsel <= 2'b0;
			id_ex_alusel <= 4'b0;
		end else begin
			id_ex_pcsel <= pcsel_o;
			id_ex_immsel <= immsel_o;
			id_ex_regwren <= regwren_o;
			id_ex_rs1sel <= rs1sel_o;
			id_ex_rs2sel <= rs2sel_o;
			id_ex_memren <= memren_o;
			id_ex_memwren <= memwren_o;
			id_ex_wbsel <= wbsel_o;
			id_ex_alusel <= alusel_o;
		end
	end

	// ---------------------------------------------------------
	// Execute Stage
	// ---------------------------------------------------------

	// M/X bypassing logic
	logic mx_bypass_rs1, mx_bypass_rs2;

	assign mx_bypass_rs1 = ex_mem_rd != 5'b0 && ex_mem_rd == id_ex_rs1;
	assign mx_bypass_rs2 = ex_mem_rd != 5'b0 && ex_mem_rd == id_ex_rs2;

	// W/X bypassing logic
	logic wx_bypass_rs1, wx_bypass_rs2;

	assign wx_bypass_rs1 = mem_wb_rd != 5'b0 && mem_wb_rd == id_ex_rs1;
	assign wx_bypass_rs2 = mem_wb_rd != 5'b0 && mem_wb_rd == id_ex_rs2;

	// ASel and BSel muxing
	logic [DWIDTH-1:0] e_rs1, e_rs2;

	assign e_rs1 = mx_bypass_rs1 ? ex_mem_alu_res : 
		wx_bypass_rs1 ? r_write_data : id_ex_rs1_data;
		
	assign e_rs2 = mx_bypass_rs2 ? ex_mem_alu_res : 
		wx_bypass_rs2 ? r_write_data : id_ex_rs2_data;

	logic [AWIDTH-1:0] e_pc;
	logic [DWIDTH-1:0] e_alu_res;

	alu #(
		.DWIDTH(DWIDTH), 
		.AWIDTH(AWIDTH)
	) e_alu (
		.pc_i (id_ex_pc),
		.rs1_i (id_ex_rs1sel ? id_ex_pc : e_rs1), 	// ASel mux
		.rs2_i (id_ex_immsel ? id_ex_imm : e_rs2), 	// BSel mux
		.opcode_i (id_ex_opcode),
		.funct3_i (id_ex_funct3),
		.funct7_i (id_ex_funct7),
		.alusel_i (id_ex_alusel),

		.res_o (e_alu_res),
		.brtaken_o ()	// produced by branch_taken_logic
	);

	// ---------------------------------------------------------
	// Branch Control Signals
	// ---------------------------------------------------------

	logic e_br_taken, breq_o, brlt_o;

	branch_control #(.DWIDTH(DWIDTH)) branch_ctrl (
		.opcode_i (id_ex_opcode),
		.funct3_i (id_ex_funct3),
		.rs1_i (e_rs1),
		.rs2_i (e_rs2),

		.breq_o (breq_o),
		.brlt_o (brlt_o)
	);

	always_comb begin : branch_taken_logic
		e_br_taken = 0;
		if (id_ex_opcode == BTYPE_OPCODE) begin
			unique case (id_ex_funct3)
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

	// PCSel logic for fetch stage mux, updates PC on next cycle
	// with computed target address if branch taken
	assign f_pcsel_i = e_br_taken | id_ex_pcsel;
	assign f_target_pc = e_alu_res;

	// Probe assignments
	assign e_pc = id_ex_pc;

	// EX/MEM pipeline register logic
	always_ff @(posedge clk or posedge reset) begin : ex_mem_pipeline_reg
		if (reset) begin
			ex_mem_pc <= 32'b0;
			ex_mem_rs2_data <= 32'b0;
			ex_mem_opcode <= 7'b0;
			ex_mem_rd <= 5'b0;
			ex_mem_rs2 <= 5'b0;
			ex_mem_funct3 <= 3'b0;

			ex_mem_alu_res <= 32'b0;
		end else begin
			ex_mem_pc <= id_ex_pc;
			ex_mem_rs2_data <= id_ex_rs2_data;
			ex_mem_opcode <= id_ex_opcode;
			ex_mem_rd <= id_ex_rd;
			ex_mem_rs2 <= id_ex_rs2;
			ex_mem_funct3 <= id_ex_funct3;

			ex_mem_alu_res <= e_alu_res;
		end
	end

	always_ff @(posedge clk or posedge reset) begin : ex_mem_control_pipeline_reg
		if (reset) begin
			ex_mem_regwren <= 1'b0;
			ex_mem_memren <= 1'b0;
			ex_mem_memwren <= 1'b0;
			ex_mem_wbsel <= 2'b0;
		end else begin
			ex_mem_regwren <= id_ex_regwren;
			ex_mem_memren <= id_ex_memren;
			ex_mem_memwren <= id_ex_memwren;
			ex_mem_wbsel <= id_ex_wbsel;
		end
	end

	// ---------------------------------------------------------
	// Memory Stage
	// ---------------------------------------------------------

	logic [2:0] m_size_encoded;
	logic [AWIDTH-1:0] m_pc, m_address;
	logic [DWIDTH-1:0] m_data_o, m_data_i;

    // read_en_i should be set to ex_mem_memren, but unfortunately tests
    // expect memory to be read on every instruction (not just load/stores)
	// and fail otherwise. Therefore, we set read_en_i to be always enabled.
	//
	// Additionally, since testbenches expect memory reads on every instruction, 
	// we must default to reading words (see size_encoded_i instantiation below)
	memory #(
		.AWIDTH(AWIDTH),
		.DWIDTH(DWIDTH),
		.BASE_ADDR(32'h01000000)
	) dmemory (
		.clk(clk),
		.rst(reset),
		.addr_i(m_address),
		.data_i(m_data_i),
		.size_encoded_i((ex_mem_opcode == LOAD_OPCODE || ex_mem_opcode == STYPE_OPCODE) ? ex_mem_funct3 : MEM_WORD),
		.read_en_i(ex_mem_memren), // was 1'b1
		.write_en_i(ex_mem_memwren),

		.data_o(m_data_o)
	);

	// W/M bypassing logic for stores
	assign m_data_i = mem_wb_rd != 5'b0 && mem_wb_rd == ex_mem_rs2 
		? r_write_data
		: ex_mem_rs2_data;

	// Probe assignments
	assign m_pc = ex_mem_pc;
	assign m_address = ex_mem_alu_res;
	assign m_size_encoded = ex_mem_funct3[1:0];

	// MEM/WB pipeline register logic
	always_ff @(posedge clk or posedge reset) begin : mem_wb_pipeline_reg
		if (reset) begin
			mem_wb_pc <= 32'b0;
			mem_wb_alu_res <= 32'b0;
			mem_wb_rd <= 5'b0;

			mem_wb_mem_data <= 32'b0;
		end else begin
			mem_wb_pc <= ex_mem_pc;
			mem_wb_alu_res <= ex_mem_alu_res;
			mem_wb_rd <= ex_mem_rd;

			mem_wb_mem_data <= m_data_o;
		end
	end

	always_ff @(posedge clk or posedge reset) begin : mem_wb_control_pipeline_reg
		if (reset) begin
			mem_wb_regwren <= 1'b0;
			mem_wb_wbsel <= 2'b0;
		end else begin
			mem_wb_regwren <= ex_mem_regwren;
			mem_wb_wbsel <= ex_mem_wbsel;
		end
	end

	// ---------------------------------------------------------
	// Write-back Stage
	// ---------------------------------------------------------

	logic w_enable;
	logic [4:0] w_destination;
	logic [DWIDTH-1:0] w_data;
	logic [AWIDTH-1:0] w_pc;

	writeback #(
		.DWIDTH(DWIDTH), 
		.AWIDTH(AWIDTH)
	) wb (
		.pc_i (mem_wb_pc),
		.alu_res_i (mem_wb_alu_res),
		.memory_data_i (mem_wb_mem_data),
		.wbsel_i (mem_wb_wbsel),

		.writeback_data_o (w_data)
	);

	assign r_write_data = w_data; // Register file writeback data signal

	// Probe assignments
	assign w_pc = mem_wb_pc;
	assign w_enable = mem_wb_regwren;
	assign w_destination = mem_wb_rd;

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

	// program termination logic
	reg is_program = 0;
	always_ff @(posedge clk) begin
		if (if_id_insn == 32'h00000073) $finish;  // directly terminate if see ecall
		if (if_id_insn == 32'h00008067) is_program = 1;  // if see ret instruction, it is simple program test
		if (is_program && (rf.regfile[2] == 32'h01000000 + `MEM_DEPTH)) $finish;
	end

endmodule : pd5
