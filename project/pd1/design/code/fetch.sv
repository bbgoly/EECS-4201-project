/* Salman Kayani
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
	// inputs
	input logic clk,
	input logic rst,
	// outputs	
	output logic [AWIDTH - 1:0] pc_o,
    output logic [DWIDTH - 1:0] insn_o
);
    /*
     * Process definitions to be filled by
     * student below...
     */
    // --------------------------
    // Instruction Memory (ROM)
    // --------------------------
    //
    //
    logic [DWIDTH-1:0] imem [0:`MEM_DEPTH-1];

    initial begin
        $readmemh(`MEM_PATH, imem);
    end

  // --------------------------
    // Program Counter (PC) logic
    // --------------------------
    always_ff @(posedge clk) begin
        if (rst) begin
            pc_o <= BASEADDR;              // reset PC to base address
        end else begin
            pc_o <= pc_o + 4;              // increment PC by 4 (word aligned)
        end
    end

    // --------------------------
    // Instruction Fetch
    // --------------------------
    always_comb begin
        insn_o = imem[(pc_o - BASEADDR) >> 2];   // fetch instruction at PC
    end

endmodule : fetch
				
