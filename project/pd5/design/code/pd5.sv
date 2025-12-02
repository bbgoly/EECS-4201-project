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
