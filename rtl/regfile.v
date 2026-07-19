// =============================================================================
// regfile.v — 32 × 32-bit RISC-V register file
// =============================================================================
//
// RISC-V has 32 general-purpose registers (x0–x31). By the ISA:
//   - x0 is hardwired to zero: reads always return 0; writes are ignored
//   - Two read ports (rs1, rs2) and one write port (rd) for single-cycle use
//
// Timing:
//   - Reads are combinational (rd1/rd2 update as soon as ra1/ra2 change)
//   - Writes are synchronous (on rising clk when we=1)
//
// =============================================================================

module regfile (
    input  wire        clk,
    input  wire        rst,       // async active-high: clear all regs to 0
    input  wire        we,        // write enable for the write port
    input  wire [4:0]  ra1,       // read address 1 (rs1 field)
    input  wire [4:0]  ra2,       // read address 2 (rs2 field)
    input  wire [4:0]  wa,        // write address (rd field)
    input  wire [31:0] wd,        // write data
    output wire [31:0] rd1,       // read data 1
    output wire [31:0] rd2        // read data 2
);

    // Storage array: 32 registers, each 32 bits.
    // regs[0] is never used for storage; x0 is forced to 0 on the read path.
    reg [31:0] regs [0:31];

    integer i;

    // -------------------------------------------------------------------------
    // Sequential write + async reset
    // -------------------------------------------------------------------------
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < 32; i = i + 1)
                regs[i] <= 32'b0;
        end else if (we && (wa != 5'd0)) begin
            // Ignore writes to x0 so software "addi x0, ..." cannot change it.
            regs[wa] <= wd;
        end
    end

    // -------------------------------------------------------------------------
    // Combinational reads
    // -------------------------------------------------------------------------
    // Reading x0 always yields 0, even if regs[0] held junk.
    assign rd1 = (ra1 == 5'd0) ? 32'b0 : regs[ra1];
    assign rd2 = (ra2 == 5'd0) ? 32'b0 : regs[ra2];

endmodule
