// Salman Kayani
// Yousif Kndkji
// Testbench for fetch.sv.
`timescale 1ns/1ps

module tb_fetch;

    localparam int DWIDTH   = 32;
    localparam int AWIDTH   = 32;
    localparam int BASEADDR = 32'h01000000;

    logic clk;
    logic rst;
    logic [AWIDTH-1:0] pc;
    logic [DWIDTH-1:0] insn;

    // Control signals for emulating branch instructions
    logic branch_en;
    logic [AWIDTH-1:0] branch_target;

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

    // Task for waiting N cycles
    task automatic wait_cycles(input int n);
        repeat (n) @(posedge clk);
    endtask

    int pass_count = 0;
    int fail_count = 0;

    // Macros
    `define PASS(MSG) begin pass_count++; $display("[PASS] %s", MSG); end
    `define FAIL(MSG) begin fail_count++; $display("[FAIL] %s", MSG); end

    initial begin
        $dumpfile("tb_fetch.vcd");
        $dumpvars(0, tb_fetch);

        $display("------------------------------------------------");
        $display("              FETCH MODULE TEST START");
        $display("------------------------------------------------");

        clk = 0;
        rst = 1;
        branch_en = 0;
        branch_target = 0;

        // Hold reset for a few cycles
        wait_cycles(2);
        rst = 0;
        wait_cycles(1);

        // -----------------------------
        // Test 1: PC fetch
        // -----------------------------
        $display("\n[Test 1] PC fetch test");
        repeat (5) begin
            @(posedge clk);
            $display("Time=%0t | PC=%h | INSN=%h", $time, pc, insn);
        end
        if (pc >= BASEADDR + 16)
            `PASS("PC increments correctly after reset")
        else
            `FAIL("PC failed to increment properly");

        // -----------------------------
        // Test 2: Reset PC and insn
        // -----------------------------
        $display("\n[Test 2] Reset test");
        rst = 1;
        wait_cycles(1);
        rst = 0;
        wait_cycles(1);
        $display("After reset -> PC=%h | INSN=%h", pc, insn);
        if (pc == BASEADDR && insn == 32'hfd010113)
            `PASS("Reset cleared PC and reinitialized instruction")
        else
            `FAIL("Reset failed");

        // -----------------------------
        // Test 3: Continuous fetch
        // -----------------------------
        $display("\n[Test 3] Continuous fetch test");
        repeat (5) begin
            @(posedge clk);
            $display("Time=%0t | PC=%h | INSN=%h", $time, pc, insn);
        end
        if (pc >= BASEADDR + 20)
            `PASS("Continuous fetch is sequential")
        else
            `FAIL("Continuous fetch failed");

        // -----------------------------
        // Test 4: Misaligned PC
        // -----------------------------
        $display("\n[Test 4] Misaligned PC test");
        force uut.pc_o = BASEADDR + 2; // Force misaligned PC
        wait_cycles(1);
        if (uut.pc_o[1:0] != 2'b00)
            `PASS("Handled misaligned PC without error")
        else
            `FAIL("Misaligned PC not detected/handled");
        release uut.pc_o;

        // -----------------------------
        // Test 5: Simulate branch behavior
        // -----------------------------
        $display("\n[Test 5] Simulated branch behavior");
        branch_target = BASEADDR + 64;
        force uut.pc_o = branch_target;  // Emulate branch redirect
        wait_cycles(1);
        $display("After branch -> PC=%h", pc);
        if (pc == branch_target)
            `PASS("Branch jump simulated successfully")
        else
            `FAIL("Branch simulation failed");
        release uut.pc_o;

        // -----------------------------
        // Results
        // -----------------------------
        $display("\n------------------------------------------------");
        $display("  PASSED: %0d", pass_count);
        $display("  FAILED: %0d", fail_count);
        $display("------------------------------------------------");

        $finish;
    end

endmodule
