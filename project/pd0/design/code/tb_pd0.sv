`timescale 1ns/1ps
import constants_pkg::*;

module tb_pd0;

    // Parameters
    localparam int DWIDTH = 32;

    // Clock and reset
    logic clk;
    logic rst;

    // DUT signals for ALU
    logic [DWIDTH-1:0] alu_op1, alu_op2, alu_res;
    logic [1:0]        alu_sel;
    logic              alu_zero, alu_neg;

    // DUT signals for register
    logic [DWIDTH-1:0] reg_in, reg_out;

    // DUT signals for pipeline
    logic [DWIDTH-1:0] tsp_op1, tsp_op2, tsp_res;

    // Instantiate DUTs
    alu #(.DWIDTH(DWIDTH)) dut_alu (
        .sel_i (alu_sel),
        .op1_i (alu_op1),
        .op2_i (alu_op2),
        .res_o (alu_res),
        .zero_o(alu_zero),
        .neg_o (alu_neg)
    );

    reg_rst #(.DWIDTH(DWIDTH)) dut_reg (
        .clk   (clk),
        .rst   (rst),
        .in_i  (reg_in),
        .out_o (reg_out)
    );

    three_stage_pipeline #(.DWIDTH(DWIDTH)) dut_tsp (
        .clk   (clk),
        .rst   (rst),
        .op1_i (tsp_op1),
        .op2_i (tsp_op2),
        .res_o (tsp_res)
    );

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk; // 10ns period

    // Test sequence
    initial begin
        // Initialize
        rst = 1;
        alu_op1 = 0; alu_op2 = 0; alu_sel = ADD;
        reg_in  = 0;
        tsp_op1 = 0; tsp_op2 = 0;

        #20; // hold reset for 2 cycles
        rst = 0;

        // --- Test ALU ---
        alu_op1 = 10; alu_op2 = 5; alu_sel = ADD; #10;
        $display("[ALU] %0d + %0d = %0d", alu_op1, alu_op2, alu_res);

        alu_sel = SUB; #10;
        $display("[ALU] %0d - %0d = %0d", alu_op1, alu_op2, alu_res);

        alu_sel = AND; #10;
        $display("[ALU] %0d & %0d = %0d", alu_op1, alu_op2, alu_res);

        alu_sel = OR; #10;
        $display("[ALU] %0d | %0d = %0d", alu_op1, alu_op2, alu_res);

        // --- Test Register ---
        reg_in = 32'hA5A5; #10;
        $display("[REG] in=%h, out=%h", reg_in, reg_out);

        // --- Test Pipeline ---
        tsp_op1 = 8; tsp_op2 = 4; #50; // wait a few cycles
        $display("[TSP] op1=%0d, op2=%0d, out=%0d", tsp_op1, tsp_op2, tsp_res);

        tsp_op1 = 12; tsp_op2 = 3; #50;
        $display("[TSP] op1=%0d, op2=%0d, out=%0d", tsp_op1, tsp_op2, tsp_res);

        $finish;
    end

endmodule

