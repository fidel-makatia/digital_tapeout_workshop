// ============================================================================
// Register File / Data RAM - 256 x 8-bit
// ============================================================================
// This module is FROZEN. Do not modify.
//
// Simple single-port synchronous RAM used as data memory.
// Address 0xFF is memory-mapped to GPIO output register.
// ============================================================================

module regfile (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        we,        // Write enable
    input  wire [7:0]  addr,      // Address
    input  wire [7:0]  wdata,     // Write data
    output reg  [7:0]  rdata      // Read data
);

    // 256 bytes of data memory
    reg [7:0] mem [0:255];

    integer i;

    // Synchronous read and write
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rdata <= 8'h00;
            for (i = 0; i < 256; i = i + 1) begin
                mem[i] <= 8'h00;
            end
        end else begin
            if (we) begin
                mem[addr] <= wdata;
            end
            rdata <= mem[addr];
        end
    end

endmodule
