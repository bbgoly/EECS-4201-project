// Salman Kayani
// Yousif Kndkji
// Testbench for memory.sv.
`timescale 1ps/1ps

module tb_memory;

    parameter int DWIDTH = 32;
    parameter int AWIDTH = 32;
    parameter logic [31:0] BASE_ADDR = 32'h01000000;

    logic clk;
    logic rst;
    logic [AWIDTH-1:0] addr_i;
    logic [DWIDTH-1:0] data_i;
    logic [DWIDTH-1:0] data_o;
    logic read_en_i;
    logic write_en_i;

    memory #(
        .AWIDTH(AWIDTH),
        .DWIDTH(DWIDTH)
    ) dut (
        .clk(clk),
        .rst(rst),
        .addr_i(addr_i),
        .data_i(data_i),
        .data_o(data_o),
        .read_en_i(read_en_i),
        .write_en_i(write_en_i)
    );

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk;

    // Task for checking output
    task check_output(input [DWIDTH-1:0] expected, string msg);
        if (data_o !== expected)
            $error("[%0t] MISMATCH: %s | Expected = %h, Got = %h", $time, msg, expected, data_o);
        else
            $display("[%0t] PASS: %s | Output = %h", $time, msg, data_o);
    endtask

    initial begin
        $dumpfile("tb_memory.vcd");
        $dumpvars(0, tb_memory);

        rst = 1;
        addr_i = BASE_ADDR;
        data_i = 0;
        read_en_i = 0;
        write_en_i = 0;
        #12 rst = 0;

        // Test 1: Write then read
        @(posedge clk);
        addr_i = BASE_ADDR + 4;
        data_i = 32'hCAFEBABE;
        write_en_i = 1;
        @(posedge clk);
        write_en_i = 0;

        @(posedge clk);
        read_en_i = 1;
        #1 check_output(32'hCAFEBABE, "Simple write/read");

        // Test 2: Write while reading another address
        @(posedge clk);
        addr_i = BASE_ADDR + 8;
        data_i = 32'hA5A5A5A5;
        write_en_i = 1;
        read_en_i  = 1;
        @(posedge clk);
        write_en_i = 0;
        #1 $display("[%0t] INFO: Simultaneous read/write test => %h", $time, data_o);

        // Test 3: Overwriting existing memory
        @(posedge clk);
        addr_i = BASE_ADDR + 4;
        data_i = 32'hFACEFACE;
        write_en_i = 1;
        @(posedge clk);
        write_en_i = 0;
        @(posedge clk);
        read_en_i = 1;
        #1 check_output(32'hFACEFACE, "Overwriting same address");

        // Test 4: Unaligned address
        @(posedge clk);
        addr_i = BASE_ADDR + 5;
        write_en_i = 1;
        data_i = 32'h12345678;
        @(posedge clk);
        write_en_i = 0;

        @(posedge clk);
        read_en_i = 1;
        #1 $display("[%0t] INFO: Unaligned access @ %h => %h", $time, addr_i, data_o);

        // Test 5: No reading when disabled
        read_en_i = 0;
        #1 assert (data_o == 0)
            else $error("[%0t] Read data should be cleared when read_en_i=0", $time);

        $display("[%0t] All memory tests completed.", $time);
        #10 $finish;
    end

endmodule
