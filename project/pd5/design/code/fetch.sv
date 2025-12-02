/*
 * Yousif Kndkji
 * Salman Kayani
 * Module: fetch
 *
 * Description: Fetch stage
 *
 * Inputs:
 * 1) clk
 * 2) rst signal
 *
 * Outputs:
 * 1) AWIDTH wide program counter pc_o
 * 2) DWIDTH wide instruction output insn_o
 */

module fetch #(
	parameter int DWIDTH=32,
	parameter int AWIDTH=32,
	parameter int BASEADDR=32'h01000000
)(
	input logic clk,
	input logic rst,
	input logic pcsel_i,
	input logic [AWIDTH-1:0] target_pc_i,
	
	output logic [AWIDTH-1:0] pc_o,
	output logic [DWIDTH-1:0] insn_o
);

    logic [AWIDTH - 1:0] pc;
      
    always_ff @(posedge clk) begin 
        if (rst) begin
            pc <= BASEADDR;
        end else if (pcsel_i) begin
			pc <= target_pc_i;
		end else begin
            pc <= pc + 32'd4;
        end
    end
       
	assign pc_o = pc;

endmodule : fetch