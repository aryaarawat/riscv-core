// =============================================================================
// dmem.v — Synchronous-write data memory with byte/half/word access
// =============================================================================
//
// Byte-addressable memory backing RV32I loads/stores:
//   funct3 (width): 000 LB  001 LH  010 LW  100 LBU  101 LHU
//                   000 SB  001 SH  010 SW
//
// Reads are combinational; writes occur on rising clk when we=1.
//
// =============================================================================

module dmem #(
    parameter DEPTH = 1024
) (
    input  wire        clk,
    input  wire        we,
    input  wire [2:0]  width,     // funct3
    input  wire [31:0] addr,
    input  wire [31:0] wdata,
    output reg  [31:0] rdata
);

    // Byte array so unaligned half/word handling is straightforward for a
    // teaching core (we still assume naturally aligned accesses in tests).
    reg [7:0] mem [0:DEPTH-1];

    integer i;
    initial begin
        for (i = 0; i < DEPTH; i = i + 1)
            mem[i] = 8'b0;
    end

    // -------------------------------------------------------------------------
    // Combinational read with sign/zero extend
    // -------------------------------------------------------------------------
    wire [31:0] addr_i = addr; // alias for clarity
    wire [7:0]  b0 = mem[addr_i];
    wire [7:0]  b1 = mem[addr_i + 1];
    wire [7:0]  b2 = mem[addr_i + 2];
    wire [7:0]  b3 = mem[addr_i + 3];

    always @(*) begin
        case (width)
            3'b000: rdata = {{24{b0[7]}}, b0};                 // LB
            3'b001: rdata = {{16{b1[7]}}, b1, b0};             // LH
            3'b010: rdata = {b3, b2, b1, b0};                  // LW
            3'b100: rdata = {24'b0, b0};                       // LBU
            3'b101: rdata = {16'b0, b1, b0};                   // LHU
            default: rdata = {b3, b2, b1, b0};
        endcase
    end

    // -------------------------------------------------------------------------
    // Synchronous write
    // -------------------------------------------------------------------------
    always @(posedge clk) begin
        if (we) begin
            case (width)
                3'b000: begin // SB
                    mem[addr_i] <= wdata[7:0];
                end
                3'b001: begin // SH
                    mem[addr_i]     <= wdata[7:0];
                    mem[addr_i + 1] <= wdata[15:8];
                end
                3'b010: begin // SW
                    mem[addr_i]     <= wdata[7:0];
                    mem[addr_i + 1] <= wdata[15:8];
                    mem[addr_i + 2] <= wdata[23:16];
                    mem[addr_i + 3] <= wdata[31:24];
                end
                default: ;
            endcase
        end
    end

endmodule
