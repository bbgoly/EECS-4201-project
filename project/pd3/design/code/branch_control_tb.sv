`timescale 1ns/1ps

module branch_control_tb;

// UUT inputs
logic [6:0] opcode_i;
logic [2:0] funct3_i;
logic [31:0] rs1_i;
logic [31:0] rs2_i;

// UUT outputs
logic breq_o;
logic brlt_o;

branch_control #(.DWIDTH(32)) uut (
	.opcode_i(opcode_i),
	.funct3_i(funct3_i),
	.rs1_i(rs1_i),
	.rs2_i(rs2_i),

	.breq_o(breq_o),
	.brlt_o(brlt_o)
);

task automatic check_branch_control(
	input logic [6:0] opcode,
	input logic [2:0] funct3,
	input logic [31:0] rs1,
	input logic [31:0] rs2,
	input logic exp_breq,
	input logic exp_brlt
);
begin
	opcode_i = opcode;
	funct3_i = funct3;
	rs1_i = rs1;
	rs2_i = rs2;

	#5; // allow signals to settle

	$display("BRANCH_CONTROL: opcode=%b funct3=%b rs1=%d rs2=%d | breq=%b brlt=%b",
	          opcode_i, funct3_i, rs1_i, rs2_i, breq_o, brlt_o);

	if (breq_o !== exp_breq)
		$fatal("ERROR: breq_o mismatch (got %b, expected %b) for opcode=%b funct3=%b rs1=%b rs2=%b",
				breq_o, exp_breq, opcode_i, funct3_i, rs1_i, rs2_i);
	
	if (brlt_o !== exp_brlt)
		$fatal("ERROR: brlt_o mismatch (got %b, expected %b) for opcode=%b funct3=%b rs1=%b rs2=%b",
				brlt_o, exp_brlt, opcode_i, funct3_i, rs1_i, rs2_i);
end
endtask

localparam BTYPE_OPCODE = 7'b1100011;
localparam BREQ_FUNCT3 = 3'b000;
localparam BRLT_FUNCT3 = 3'b100;

initial begin
	$display("=== BEGIN BRANCH CONTROL UNIT TESTS ===");

	// BEQ taken
	check_branch_control(BTYPE_OPCODE, BREQ_FUNCT3, 32'd10, 32'd10, 1'b1, 1'b0);

	// BEQ not taken
	check_branch_control(BTYPE_OPCODE, BREQ_FUNCT3, 32'd10, 32'd20, 1'b0, 1'b0);

	// BLT taken
	check_branch_control(BTYPE_OPCODE, BRLT_FUNCT3, 32'd10, 32'd20, 1'b0, 1'b1);

	// BLT not taken
	check_branch_control(BTYPE_OPCODE, BRLT_FUNCT3, 32'd20, 32'd10, 1'b0, 1'b0);

	// Non-branch instruction (should not set any branch signals)
	check_branch_control(BTYPE_OPCODE, 3'b000, 32'd10, 32'd10, 1'b0, 1'b0);

	$display("=== ALL BRANCH CONTROL UNIT TESTS PASSED ===");
	$finish;
end

endmodule : branch_control_tb