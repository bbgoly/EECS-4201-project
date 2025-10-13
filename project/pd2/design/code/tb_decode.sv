// Salman Kayani
`timescale 1ns/1ps
`include "constants.svh"

module tb_decode;
    logic clk, rst;
    logic [31:0] insn_i, pc_i;
    logic [31:0] pc_o, insn_o, imm_o;
    logic [6:0] opcode_o, funct7_o;
    logic [4:0] rd_o, rs1_o, rs2_o, shamt_o;
    logic [2:0] funct3_o;

    // Instantiate UUT
    decode uut (
        .clk(clk),
        .rst(rst),
        .insn_i(insn_i),
        .pc_i(pc_i),
        .pc_o(pc_o),
        .insn_o(insn_o),
        .opcode_o(opcode_o),
        .rd_o(rd_o),
        .rs1_o(rs1_o),
        .rs2_o(rs2_o),
        .funct7_o(funct7_o),
        .funct3_o(funct3_o),
        .shamt_o(shamt_o),
        .imm_o(imm_o)
    );

    always #5 clk = ~clk;
    
    // Task: check all important decoded fields against expected values
    task check_fields(input [31:0] exp_pc, exp_opcode, exp_rd, exp_rs1, exp_rs2, exp_funct3, exp_funct7);
        #1;
        if (pc_o   !== exp_pc)      $fatal("PC mismatch: %h != %h", pc_o, exp_pc);
        if (opcode_o !== exp_opcode)$fatal("Opcode mismatch: %h != %h", opcode_o, exp_opcode);
        if (rd_o   !== exp_rd)      $fatal("RD mismatch: %h != %h", rd_o, exp_rd);
        if (rs1_o  !== exp_rs1)     $fatal("RS1 mismatch: %h != %h", rs1_o, exp_rs1);
        if (rs2_o  !== exp_rs2)     $fatal("RS2 mismatch: %h != %h", rs2_o, exp_rs2);
        if (funct3_o !== exp_funct3)$fatal("Funct3 mismatch: %h != %h", funct3_o, exp_funct3);
        if (funct7_o !== exp_funct7)$fatal("Funct7 mismatch: %h != %h", funct7_o, exp_funct7);
        $display("Decode OK for instruction %h", insn_i);
    endtask

    initial begin
	$display("=== Starting decode Testbench ===");
        clk = 0; rst = 1; pc_i = 32'h01000000;
        #10 rst = 0;

        // R-type: ADD x3,x4,x5  => funct7=0000000, rs2=5, rs1=4, funct3=000, rd=3, opcode=0110011
        insn_i = 32'b0000000_00101_00100_000_00011_0110011;
        #10 check_fields(pc_i, 7'b0110011, 5'd3, 5'd4, 5'd5, 3'd0, 7'd0);

        // I-type: ADDI x5,x6,10  => opcode=0010011, funct3=000
        insn_i = 32'b000000000010_00110_000_00101_0010011;
        #10 check_fields(pc_i, 7'b0010011, 5'd5, 5'd6, 5'd0, 3'd0, 7'd0);

        // S-type: SW x7,8(x9)
        insn_i = 32'b0000000_00111_01001_010_01000_0100011;
        #10 check_fields(pc_i, 7'b0100011, 5'd0, 5'd9, 5'd7, 3'd2, 7'd0);

        // B-type: BEQ x1,x2,offset
        insn_i = 32'b0000000_00010_00001_000_00010_1100011;
        #10 check_fields(pc_i, 7'b1100011, 5'd0, 5'd1, 5'd2, 3'd0, 7'd0);

        $display("=== All decode tests completed successfully ===");
        $finish;
    end
endmodule
