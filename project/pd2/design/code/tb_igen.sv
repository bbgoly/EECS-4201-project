// Salman Kayani
`timescale 1ns/1ps

module tb_igen;

    localparam int DWIDTH = 32;

    logic [6:0] opcode_i;
    logic [DWIDTH-1:0] insn_i;

    logic [31:0] imm_o;

    // Instantiate DUT
    igen #(.DWIDTH(DWIDTH)) dut (
        .opcode_i(opcode_i),
        .insn_i(insn_i),
        .imm_o(imm_o)
    );

  // Task for checking immediate output for a given instruction
    task check_imm(input [6:0] opcode, input [DWIDTH-1:0] insn, input [31:0] expected);
        begin
            opcode_i = opcode;
            insn_i   = insn;
            #1;
            if (imm_o !== expected) begin
                $display("IMM mismatch for opcode=%b: got %h expected %h", opcode, imm_o, expected);
                $fatal(1, "IMM mismatch for opcode %b: got %h expected %h", opcode, imm_o, expected);
            end else begin
                $display("IMM OK for opcode=%b => %h", opcode, imm_o);
            end
        end
    endtask

    initial begin
        $display("=== Starting igen Testbench ===");

        // I-type
        check_imm(7'b0010011, 32'h00200000, {{20{1'b0}}, 12'h002});

        // Load (lw)
        check_imm(7'b0000011, 32'h00400000, {{20{1'b0}}, 12'h004});

        // JALR
        check_imm(7'b1100111, 32'h00800000, {{20{1'b0}}, 12'h008});

        // S-type (store) — imm = {31:25, 11:7}
        check_imm(7'b0100011, 32'b0000000_00000_00000_000_01000_0100011, 32'h00000008);

        // B-type (branch) — imm = {31,7,30:25,11:8,0}
        check_imm(7'b1100011, 32'b0000000_00000_00000_000_10000_1100011, 32'h00000010);

        // U-type (LUI) — imm = {31:12, zeros}
        check_imm(7'b0110111, 32'h00012000, 32'h00012000);

        // U-type (AUIPC)
        check_imm(7'b0010111, 32'h00034000, 32'h00034000);

        // J-type (JAL) — imm = {{11{bit31}}, bit31, bits[19:12], bit20, bits[30:21], 0}
        check_imm(7'b1101111, 32'h00001000, 32'h00001000);

        $display("=== All igen tests completed successfully ===");
        $finish;
    end

endmodule
