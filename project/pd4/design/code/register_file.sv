/*
 * Salman Kayani
 * Module: register_file
 *
 * Description: Branch control logic. Only sets the branch control bits based on the
 * branch instruction
 *
 * Inputs:
 * 1) clk
 * 2) reset signal rst
 * 3) 5-bit rs1 address rs1_i
 * 4) 5-bit rs2 address rs2_i
 * 5) 5-bit rd address rd_i
 * 6) DWIDTH-wide data writeback datawb_i
 * 7) register write enable regwren_i
 * Outputs:
 * 1) 32-bit rs1 data rs1data_o
 * 2) 32-bit rs2 data rs2data_o
 */

module register_file #(
    parameter int DWIDTH = 32
)(
    input  logic                     clk,
    input  logic                     rst,
    input  logic       [4:0]         rs1_i,
    input  logic       [4:0]         rs2_i,
    input  logic       [4:0]         rd_i,
    input  logic [DWIDTH-1:0]        datawb_i,
    input  logic                     regwren_i,
    output logic [DWIDTH-1:0]        rs1data_o,
    output logic [DWIDTH-1:0]        rs2data_o
);


    localparam logic [DWIDTH-1:0] STACK_INIT = 32'h0110_0000;

    logic [DWIDTH-1:0] regfile [31:0];

    integer i;

    // ---------------------------------------------------------
    // Reset and write logic
    // ---------------------------------------------------------

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            // Clear everything, then set SP to STACK_INIT
            for (i = 0; i < 32; i = i + 1) begin
                regfile[i] <= '0;
            end
            regfile[2] <= STACK_INIT; // x2 = stack pointer
        end else begin
            // Commit data on clock edge if enabled
            if (regwren_i && (rd_i != 5'd0)) begin
                regfile[rd_i] <= datawb_i;
            end
            // x0
            regfile[0] <= '0;
        end
    end

    // ---------------------------------------------------------
    // Reading logic
    // ---------------------------------------------------------
    always_comb begin
        if (rs1_i == 5'd0) rs1data_o = '0;
        else               rs1data_o = regfile[rs1_i];

        if (rs2_i == 5'd0) rs2data_o = '0;
        else               rs2data_o = regfile[rs2_i];
    end

endmodule : register_file
