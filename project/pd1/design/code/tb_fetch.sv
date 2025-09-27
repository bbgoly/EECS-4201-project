// Salman Kayani
// Testbench for fetch.sv.
`timescale 1ns/1ps

module tb_fetch;

    // Parameters
    localparam int DWIDTH   = 32;
    localparam int AWIDTH   = 32;
    localparam int BASEADDR = 32'h01000000;

    logic clk;
    logic rst;
    logic [AWIDTH-1:0] pc;
    logic [DWIDTH-1:0] insn;

    fetch #(
        .DWIDTH(DWIDTH),
        .AWIDTH(AWIDTH),
        .BASEADDR(BASEADDR)
    ) uut (
        .clk(clk),
        .rst(rst),
        .pc_o(pc),
        .insn_o(insn)
    );

    // Clock generator: 10ns period
    always #5 clk = ~clk;

    initial begin
 
        clk = 0;
        rst = 1;

        // Hold reset for 2 cycles
        #20;
        rst = 0;

        // Run for 10 cycles
        repeat (10) begin
            @(posedge clk);
            $display("Time=%0t | PC=%h | INSN=%h", $time, pc, insn);
        end

        $finish;
    end

endmodule

