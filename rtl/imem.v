// =============================================================================
// imem.v — Combinational instruction memory
// =============================================================================
//
// Word-addressed ROM. The CPU presents a byte address (PC); we use bits
// [31:2] as the word index. Contents are loaded at sim elaboration time from
// a hex file via $readmemh (one 32-bit word per line).
//
// =============================================================================

module imem #(
    parameter DEPTH     = 64,
    parameter MEM_FILE  = "sw/smoke.hex"
) (
    input  wire [31:0] addr,
    output wire [31:0] instr
);

    reg [31:0] mem [0:DEPTH-1];
    integer i;

    // Pre-clear so unread locations are 0; $readmemh then overlays the hex file.
    // (Icarus may still warn if the file has fewer words than DEPTH — harmless.)
    initial begin
        for (i = 0; i < DEPTH; i = i + 1)
            mem[i] = 32'b0;
        $readmemh(MEM_FILE, mem);
    end

    assign instr = mem[addr[31:2]];

endmodule
