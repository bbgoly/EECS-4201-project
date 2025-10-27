/*
 * Salman Kayani
 * Testbench for register_file.sv.
 */

`timescale 1ns/1ps

module tb_register_file;

  localparam int DWIDTH = 32;

  logic clk;
  logic rst;
  logic [4:0] rs1_i, rs2_i, rd_i;
  logic [DWIDTH-1:0] datawb_i;
  logic regwren_i;
  logic [DWIDTH-1:0] rs1data_o, rs2data_o;

  register_file #(.DWIDTH(DWIDTH)) dut (
    .clk(clk),
    .rst(rst),
    .rs1_i(rs1_i),
    .rs2_i(rs2_i),
    .rd_i(rd_i),
    .datawb_i(datawb_i),
    .regwren_i(regwren_i),
    .rs1data_o(rs1data_o),
    .rs2data_o(rs2data_o)
  );

  // Clock generation (10ns period)
  always #5 clk = ~clk;

  // Writing task
  task automatic write_reg(input [4:0] rd, input [DWIDTH-1:0] data);
    begin
      @(negedge clk);
      rd_i = rd;
      datawb_i = data;
      regwren_i = 1;
      @(negedge clk);
      regwren_i = 0;
    end
  endtask

  // Reading task
  task automatic read_reg(input [4:0] rs, output [DWIDTH-1:0] data);
    begin
      @(posedge clk);
      rs1_i = rs;
      #1 data = rs1data_o;
    end
  endtask

  initial begin
    clk = 0;
    rst = 1;
    rs1_i = 0;
    rs2_i = 0;
    rd_i = 0;
    datawb_i = 0;
    regwren_i = 0;

    // Apply reset
    $display("\n=== Register File Testbench ===");
    $display("Applying reset...");
    @(negedge clk);
    rst = 1;
    @(negedge clk);
    rst = 0;
    @(posedge clk);

    // Check x2 (stack pointer) initialization
    rs1_i = 5'd2;
    #1;
    if (rs1data_o !== 32'h01100000)
      $display("FAIL: x2 not initialized correctly. Got %h", rs1data_o);
    else
      $display("PASS: x2 correctly initialized to %h", rs1data_o);

    // Test write/read for x5
    write_reg(5'd5, 32'hDEADBEEF);
    rs1_i = 5'd5;
    #1;
    if (rs1data_o !== 32'hDEADBEEF)
      $display("FAIL: Write/Read mismatch for x5. Got %h", rs1data_o);
    else
      $display("PASS: Write/Read match for x5 = %h", rs1data_o);

    // Test x0 immutability
    write_reg(5'd0, 32'h12345678);
    rs1_i = 5'd0;
    #1;
    if (rs1data_o !== 32'h0)
      $display("FAIL: x0 should always read 0. Got %h", rs1data_o);
    else
      $display("PASS: x0 correctly reads 0.");

    // Overwrite x5 and verify new value
    write_reg(5'd5, 32'hCAFEBABE);
    rs1_i = 5'd5;
    #1;
    if (rs1data_o !== 32'hCAFEBABE)
      $display("FAIL: Overwrite failed for x5. Got %h", rs1data_o);
    else
      $display("PASS: Overwrite successful for x5 = %h", rs1data_o);

    // Test simultaneous read of rs1/rs2
    write_reg(5'd10, 32'hA5A5A5A5);
    write_reg(5'd11, 32'h5A5A5A5A);
    rs1_i = 5'd10;
    rs2_i = 5'd11;
    #1;
    if (rs1data_o === 32'hA5A5A5A5 && rs2data_o === 32'h5A5A5A5A)
      $display("PASS: Dual read (rs1=x10, rs2=x11) correct.");
    else
      $display("FAIL: Dual read mismatch. rs1=%h rs2=%h", rs1data_o, rs2data_o);

    $display("\nAll tests completed.\n");
    $finish;
  end

endmodule
