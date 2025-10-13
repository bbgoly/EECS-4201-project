// Salman Kayani
`timescale 1ns / 1ps

module tb_control;

    // DUT inputs
    logic [31:0] insn_i;
    logic [6:0] opcode_i;
    logic [6:0] funct7_i;
    logic [2:0] funct3_i;

    // DUT outputs
    logic pcsel_o;
    logic immsel_o;
    logic regwren_o;
    logic rs1sel_o;
    logic rs2sel_o;
    logic memren_o;
    logic memwren_o;
    logic [1:0] wbsel_o;
    logic [3:0] alusel_o;

    // Instantiate DUT (with proper port names)
    control dut (
        .insn_i(insn_i),
        .opcode_i(opcode_i),
        .funct7_i(funct7_i),
        .funct3_i(funct3_i),
        .pcsel_o(pcsel_o),
        .immsel_o(immsel_o),
        .regwren_o(regwren_o),
        .rs1sel_o(rs1sel_o),
        .rs2sel_o(rs2sel_o),
        .memren_o(memren_o),
        .memwren_o(memwren_o),
        .wbsel_o(wbsel_o),
        .alusel_o(alusel_o)
    );

    // ==========================================================
    // TASK: check_control
    // ==========================================================
    task automatic check_control(
        input logic [31:0] insn,
        input logic [6:0] opcode,
        input logic [2:0] funct3,
        input logic [6:0] funct7,
        input logic exp_regwren,
        input logic exp_memwren
    );
    begin
        insn_i    = insn;
        opcode_i  = opcode;
        funct3_i  = funct3;
        funct7_i  = funct7;

        #5; // allow signals to settle

        $display("CTRL: opcode=%b funct3=%b funct7=%b | regwren=%b memwren=%b alusel=%b",
                  opcode_i, funct3_i, funct7_i, regwren_o, memwren_o, alusel_o);

        // ---- Validate regwren ----
        if (regwren_o !== exp_regwren)
            $fatal(1, "regwren mismatch (got %b expected %b) for opcode=%b funct3=%b funct7=%b",
                   regwren_o, exp_regwren, opcode_i, funct3_i, funct7_i);

        // ---- Validate memwren ----
        if (memwren_o !== exp_memwren)
            $fatal(1, "memwren mismatch (got %b expected %b) for opcode=%b funct3=%b funct7=%b",
                   memwren_o, exp_memwren, opcode_i, funct3_i, funct7_i);
    end
    endtask


    // ==========================================================
    // TEST SEQUENCE
    // ==========================================================
    initial begin
        $display("=== BEGIN CONTROL UNIT TESTS ===");

        // ---- R-type (ADD)
        check_control(32'b0000000_00010_00001_000_00011_0110011,
                      7'b0110011, 3'b000, 7'b0000000,
                      1'b1, 1'b0);

        // ---- R-type (SUB)
        check_control(32'b0100000_00010_00001_000_00011_0110011,
                      7'b0110011, 3'b000, 7'b0100000,
                      1'b1, 1'b0);

        // ---- I-type (ADDI)
        check_control(32'b000000000101_00001_000_00011_0010011,
                      7'b0010011, 3'b000, 7'b0000000,
                      1'b1, 1'b0);

        // ---- Load (LW)
        check_control(32'b000000000100_00001_010_00011_0000011,
                      7'b0000011, 3'b010, 7'b0000000,
                      1'b1, 1'b0);

        // ---- Store (SW)
        check_control(32'b0000000_00011_00001_010_00100_0100011,
                      7'b0100011, 3'b010, 7'b0000000,
                      1'b0, 1'b1);

        // ---- Branch (BEQ)
        check_control(32'b0000000_00011_00001_000_00100_1100011,
                      7'b1100011, 3'b000, 7'b0000000,
                      1'b0, 1'b0);

        // ---- JAL
        check_control(32'b00000000000000000000_00011_1101111,
                      7'b1101111, 3'b000, 7'b0000000,
                      1'b1, 1'b0);

        // ---- LUI
        check_control(32'b00000000000000000000_00011_0110111,
                      7'b0110111, 3'b000, 7'b0000000,
                      1'b1, 1'b0);

        // ---- Edge/unknown
        check_control(32'hFFFFFFFF,
                      7'b1111111, 3'b111, 7'b1111111,
                      1'b0, 1'b0);

        $display("=== ALL CONTROL UNIT TESTS PASSED ===");
        $finish;
    end

endmodule
