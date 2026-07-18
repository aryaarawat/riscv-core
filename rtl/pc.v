// =============================================================================
// pc.v — Program Counter register for a simple RV32 core
// =============================================================================
//
// The Program Counter (PC) holds the address of the instruction currently
// being fetched. In a real RISC-V pipeline this value usually advances by
// 4 each cycle (word-aligned 32-bit instructions), or jumps when a branch /
// jump / exception redirects control flow.
//
// This module is intentionally minimal: it is ONLY a register. It does not
// compute pc+4 or handle branches. Whatever drives `pc_next` (an adder,
// mux, or jump target) lives outside this module. That keeps the PC reusable
// once you add decode / branch logic later.
//
// =============================================================================

module pc (
    // -------------------------------------------------------------------------
    // Ports
    // -------------------------------------------------------------------------

    // System clock. All non-reset updates happen on the rising edge.
    input  wire        clk,

    // Asynchronous, active-high reset. When asserted, pc_out clears to 0
    // immediately (does not wait for a clock edge). Many educational cores
    // boot from address 0; a production core might reset to a boot ROM base.
    input  wire        rst,

    // Next PC value to load on the next rising clock edge (when not in reset).
    // Driven by external logic, e.g. sequential fetch (pc_out + 4) or a
    // branch/jump target address.
    input  wire [31:0] pc_next,

    // Current PC value. Readable by instruction memory (as the fetch address)
    // and by whatever computes the next sequential PC.
    output reg  [31:0] pc_out
);

    // -------------------------------------------------------------------------
    // Sequential logic: async-reset register
    // -------------------------------------------------------------------------
    // Sensitivity list includes BOTH clk and rst:
    //   - posedge clk  → normal load of pc_next
    //   - posedge rst  → immediate clear (asynchronous reset)
    //
    // Using `<=` (non-blocking assignment) is the correct style for
    // synthesizable sequential (flip-flop) logic in Verilog.
    always @(posedge clk or posedge rst) begin
        if (rst)
            // Reset path: force PC to zero regardless of pc_next.
            pc_out <= 32'b0;
        else
            // Clocked path: capture whatever the next-PC logic supplied.
            pc_out <= pc_next;
    end

endmodule
