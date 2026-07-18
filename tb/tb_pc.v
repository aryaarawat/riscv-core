// =============================================================================
// tb_pc.v — Self-checking testbench for the PC module
// =============================================================================
//
// This file does NOT synthesize to hardware. It is a simulation-only harness
// that:
//   1. Instantiates the DUT (device under test): module `pc`
//   2. Generates a free-running clock
//   3. Applies timed stimulus (reset, pc_next values)
//   4. Checks that pc_out matches expectations after each step
//   5. Dumps a VCD waveform file for optional viewing in a wave viewer
//
// Run with Icarus Verilog:
//   iverilog -o tb_pc.vvp rtl/pc.v tb/tb_pc.v
//   vvp tb_pc.vvp
//
// =============================================================================

// Tell the simulator that `#1` means 1 nanosecond, and that the finest
// time resolution is 1 picosecond. So `#10` = 10 ns of sim time.
`timescale 1ns/1ps

module tb_pc;

    // -------------------------------------------------------------------------
    // Testbench signals — these drive / observe the DUT
    // -------------------------------------------------------------------------

    // `reg` = driven by procedural code in this testbench (initial/always/task)
    reg clk;              // clock into the DUT
    reg rst;              // reset into the DUT
    reg [31:0] pc_next;   // next-PC value we feed the DUT

    // `wire` = driven by the DUT's output port
    wire [31:0] pc_out;   // current PC coming back from the DUT

    // Running count of failed checks. Used for the final PASS/FAIL summary.
    integer errors;

    // -------------------------------------------------------------------------
    // DUT instantiation
    // -------------------------------------------------------------------------
    // Connect testbench signals to the `pc` module ports by name.
    // `uut` = "unit under test" (common naming convention).
    pc uut (
        .clk(clk),
        .rst(rst),
        .pc_next(pc_next),
        .pc_out(pc_out)
    );

    // -------------------------------------------------------------------------
    // Clock generator
    // -------------------------------------------------------------------------
    // Toggle clk every 5 ns → 10 ns period → 100 MHz.
    // Starts at 0 (set in initial). Rising edges then occur at t = 5, 15, 25, ...
    // This `always` block runs forever in parallel with the `initial` block.
    always #5 clk = ~clk;

    // -------------------------------------------------------------------------
    // Checker helper
    // -------------------------------------------------------------------------
    // Compares the live pc_out against an expected value RIGHT NOW.
    // Call this AFTER you have waited long enough for the DUT to update
    // (e.g. after a # delay past a clock edge or async reset).
    //
    // Uses !== (case inequality) so X/Z bits count as a mismatch.
    // Plain != would treat X as "unknown" and might not flag unknowns as fails.
    task check;
        input [31:0] expected;   // value we believe pc_out should hold
        input [255:0] msg;       // short description printed with PASS/FAIL
        begin
            if (pc_out !== expected) begin
                $display("FAIL: %0s - got %0d (0x%08h), expected %0d (0x%08h)",
                         msg, pc_out, pc_out, expected, expected);
                errors = errors + 1;
            end else begin
                $display("PASS: %0s - pc_out = %0d", msg, pc_out);
            end
        end
    endtask

    // -------------------------------------------------------------------------
    // Main test sequence
    // -------------------------------------------------------------------------
    // One-shot procedural block: runs once from time 0, applies stimulus,
    // checks results, then ends the simulation with $finish.
    initial begin
        // Start capturing waveforms for every signal under tb_pc.
        // Open tb_pc.vcd in GTKWave (or similar) after the run.
        $dumpfile("tb_pc.vcd");
        $dumpvars(0, tb_pc);

        // ---- Initialize -----------------------------------------------------
        errors = 0;
        clk = 0;            // clock starts low; first rising edge at t=5 ns
        rst = 1;            // come out of power-on in reset
        pc_next = 32'd0;    // don't care while reset is held, but keep tidy

        // Hold reset long enough that at least one rising clock edge occurs
        // while rst is still high (edge at t=5 ns). #12 lands at t=12 ns,
        // safely after that edge, before we deassert reset.
        #12;
        check(32'd0, "reset forces PC to 0");

        // ---- Normal sequential loads ----------------------------------------
        // These values (4, 8, 100) pretend to be what a fetch-adder / next-PC
        // mux would produce. The PC module itself does not add 4.
        rst = 0;
        pc_next = 32'd4;
        #10;                // wait one full clock period → rising edge loads 4
        check(32'd4, "PC loads 4");

        pc_next = 32'd8;
        #10;
        check(32'd8, "PC loads 8");

        pc_next = 32'd100;
        #10;
        check(32'd100, "PC loads 100");

        // ---- Asynchronous mid-run reset -------------------------------------
        // Assert rst while PC is nonzero. Wait only #1 (1 ns) — NOT a full
        // clock period — so no rising edge happens. If pc_out clears anyway,
        // the DUT's reset is truly asynchronous (as designed).
        rst = 1;
        #1;
        check(32'd0, "mid-run reset clears PC");

        // ---- Recovery after reset -------------------------------------------
        // Deassert reset and confirm the next clocked load still works.
        rst = 0;
        pc_next = 32'd200;
        #10;
        check(32'd200, "PC recovers after reset");

        // ---- Summary --------------------------------------------------------
        if (errors == 0)
            $display("ALL TESTS PASSED");
        else
            $display("TESTS FAILED: %0d error(s)", errors);

        // End simulation. Without this, the free-running clock would run forever.
        $finish;
    end

endmodule
