/*
 * Module: memory
 *
 * Description: Byte-addressable memory implementation. Supports both read and write operations.
 * Reads are combinational and writes are performed on the rising clock edge.
 *
 * Inputs:
 * 1) clk
 * 2) rst signal
 * 3) AWIDTH address addr_i
 * 4) DWIDTH data to write data_i
 * 5) read enable signal read_en_i
 * 6) write enable signal write_en_i
 *
 * Outputs:
 * 1) DWIDTH data output data_o
 */

`include "constants.svh"

module memory #(
	// parameters
	parameter int AWIDTH = 32,
	parameter int DWIDTH = 32,
	parameter logic [31:0] BASE_ADDR = 32'h01000000
) (
	// inputs
	input logic clk,
	input logic rst,
	input logic [AWIDTH-1:0] addr_i = BASE_ADDR,
	input logic [DWIDTH-1:0] data_i,
	input logic [2:0] size_encoded_i,
	input logic read_en_i,
	input logic write_en_i,
	// outputs
	output logic [DWIDTH-1:0] data_o
//    output logic [127:0] addr_o
);

	localparam int MEM_BYTES = `MEM_DEPTH;//`LINE_COUNT * (DWIDTH/8);

    // Byte-addressable memory
	logic [DWIDTH-1:0] temp_memory [0:`LINE_COUNT - 1];
	logic [7:0] main_memory [0:MEM_BYTES - 1];
	
    logic unsigned [AWIDTH-1:0] address;
	assign address = addr_i >= BASE_ADDR 
		? (addr_i - BASE_ADDR) % MEM_BYTES
		: addr_i;

  //  assign addr_o = {address + 3, address + 2, address + 1, address};
	
    int i;
	initial begin
		$readmemh(`MEM_PATH, temp_memory);
        
		// Load data from temp_memory into main_memory
		for (i = 0; i < `LINE_COUNT; i++) begin
			main_memory[4*i]     = temp_memory[i][7:0];
			main_memory[4*i + 1] = temp_memory[i][15:8];
			main_memory[4*i + 2] = temp_memory[i][23:16];
			main_memory[4*i + 3] = temp_memory[i][31:24];
		end

        // Initialize remaining memory to zero
        for (i = 4 * `LINE_COUNT; i < MEM_BYTES; i++) begin
            main_memory[i] = 8'd0;
        end
		$display("IMEMORY: Loaded %0d 32-bit words from %s", `LINE_COUNT, `MEM_PATH);
	end

	// Combinational read logic
	always_comb begin
		data_o = '0; // default to zero
		if (read_en_i) begin
			if ($isunknown(addr_i)) begin
				data_o = '0;
			end else begin
				// Word-aligned fetch: little-endian assembly
				unique case (size_encoded_i)
					// sign-extended read
					MEM_BYTE: data_o = {{24{main_memory[address][7]}}, main_memory[address]}; // LB
					MEM_HALF: 
						data_o = {
							{16{main_memory[(address + 1) & (MEM_BYTES - 1)][7]}},
							main_memory[(address + 1) & (MEM_BYTES - 1)], 
							main_memory[address]
						}; // LH
					
					MEM_WORD: // Execute LW or fetch word-aligned instruction
						data_o = {
							main_memory[(address + 3) & (MEM_BYTES - 1)],
							main_memory[(address + 2) & (MEM_BYTES - 1)],
							main_memory[(address + 1) & (MEM_BYTES - 1)],
							main_memory[address]
						};

					// zero-extended read
					MEM_LBU: data_o = {24'd0, main_memory[address]}; // LBU
					MEM_LHU: data_o = {16'd0, main_memory[(address + 1) & (MEM_BYTES - 1)], main_memory[address]}; // LHU

					default:
						data_o = {
							main_memory[(address + 3) & (MEM_BYTES - 1)],
							main_memory[(address + 2) & (MEM_BYTES - 1)],
							main_memory[(address + 1) & (MEM_BYTES - 1)],
							main_memory[address]
						};
				endcase
			end
		end
	end

	// Sequential write logic
	always_ff @(posedge clk) begin
		if (write_en_i) begin
			if ((addr_i >= BASE_ADDR) && (addr_i + 32'd3 < BASE_ADDR + MEM_BYTES)) begin
				// Word-aligned store: little-endian assembly
				unique case (size_encoded_i & 3'b011) // mask off upper bit used for unsigned load funct3
					MEM_BYTE: main_memory[address] <= data_i[7:0]; // SB
					
					MEM_HALF: begin // SH
						main_memory[address] <= data_i[7:0];
						main_memory[(address + 1) & (MEM_BYTES - 1)] <= data_i[15:8];
					end

					MEM_WORD: begin // SW
						main_memory[address] <= data_i[7:0];
						main_memory[(address + 1) & (MEM_BYTES - 1)] <= data_i[15:8];
						main_memory[(address + 2) & (MEM_BYTES - 1)] <= data_i[23:16];
						main_memory[(address + 3) & (MEM_BYTES - 1)] <= data_i[31:24];
					end
				endcase
				$display("IMEMORY: Wrote 0x%08h to 0x%08h", data_i, addr_i);
			end else begin
				$display("IMEMORY: OOB write @0x%08h", addr_i);
			end
		end
	end
 
endmodule : memory
