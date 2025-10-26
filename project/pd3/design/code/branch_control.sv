/*
 * Module: branch_control
 *
 * Description: Branch control logic. Only sets the branch control bits based on the
 * branch instruction
 *
 * Inputs:
 * 1) 7-bit instruction opcode opcode_i
 * 2) 3-bit funct3 funct3_i
 * 3) 32-bit rs1 data rs1_i
 * 4) 32-bit rs2 data rs2_i
 *
 * Outputs:
 * 1) 1-bit operands are equal signal breq_o
 * 2) 1-bit rs1 < rs2 signal brlt_o
 */

`include "constants.svh"

 module branch_control #(
    parameter int DWIDTH=32
)(
    // inputs
    input logic [6:0] opcode_i,
    input logic [2:0] funct3_i,
    input logic [DWIDTH-1:0] rs1_i,
    input logic [DWIDTH-1:0] rs2_i,
    // outputs
    output logic breq_o,
    output logic brlt_o
);

	always_comb begin
		breq_o = 0;
		brlt_o = 0;

		if (opcode_i == BTYPE_OPCODE) begin
			unique case (funct3_i)
				BREQ_FUNCT3: breq_o = rs1_i == rs2_i;
				BRLT_FUNCT3: brlt_o = rs1_i < rs2_i; // check if signed or unsigned later
			endcase
		end
	end

endmodule : branch_control

