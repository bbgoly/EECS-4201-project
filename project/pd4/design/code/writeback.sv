/* Salman Kayani
 * Module: writeback
 *
 * Description: Write-back control stage implementation
 *
 * Inputs:
 * 1) PC pc_i
 * 2) result from alu alu_res_i
 * 3) data from memory memory_data_i
 * 4) data to select for write-back wbsel_i
 * 5) branch taken signal brtaken_i
 *
 * Outputs:
 * 1) DWIDTH wide write back data write_data_o
 * 2) AWIDTH wide next computed PC next_pc_o
 */

`include "constants.svh"

 module writeback #(
     parameter int DWIDTH=32,
     parameter int AWIDTH=32
 )(
     input logic [AWIDTH-1:0] pc_i,
     input logic [DWIDTH-1:0] alu_res_i,
     input logic [DWIDTH-1:0] memory_data_i,
     input logic [1:0] wbsel_i,
     input logic brtaken_i,

     output logic [DWIDTH-1:0] writeback_data_o,
     output logic [AWIDTH-1:0] next_pc_o
 );

    // ------------------------
    // Next PC computation
    // ------------------------
    always_comb begin
        if (brtaken_i) begin
            // Use ALU result as the next PC when branch/jump is taken
            next_pc_o = alu_res_i;
        end else begin
            // Otherwise, proceed to immediate next instruction
            next_pc_o = pc_i + 32'd4;
        end
    end

    // ------------------------
    // Writeback data selection
    // ------------------------
    always_comb begin
        unique case (wbsel_i)
            WB_ALU: writeback_data_o = alu_res_i;      	// R-type, I-type ALU operations
            WB_MEM: writeback_data_o = memory_data_i;  	// Load instructions
            WB_PC: writeback_data_o = pc_i + 32'd4;		// JAL / JALR link return value
            default: writeback_data_o = alu_res_i;		// ALU result as default
        endcase
    end

endmodule : writeback
