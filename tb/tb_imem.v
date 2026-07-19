// =============================================================================
// tb_imem.v — Self-checking testbench for instruction memory
// =============================================================================
`timescale 1ns/1ps

module tb_imem;

    reg  [31:0] addr;
    wire [31:0] instr;
    integer errors;

    imem #(.MEM_FILE("sw/imem_test.hex"), .DEPTH(16)) uut (
        .addr(addr),
        .instr(instr)
    );

    task check;
        input [31:0] expected;
        input [255:0] msg;
        begin
            if (instr !== expected) begin
                $display("FAIL: %0s - got 0x%08h expected 0x%08h", msg, instr, expected);
                errors = errors + 1;
            end else
                $display("PASS: %0s", msg);
        end
    endtask

    initial begin
        $dumpfile("tb_imem.vcd");
        $dumpvars(0, tb_imem);
        errors = 0;

        // $readmemh runs at time 0; give a tiny delay
        #1;
        addr = 32'h0000_0000; #1; check(32'h11223344, "word 0");
        addr = 32'h0000_0004; #1; check(32'hAABBCCDD, "word 1");
        addr = 32'h0000_000C; #1; check(32'hDEADBEEF, "word 3");

        if (errors == 0)
            $display("ALL TESTS PASSED");
        else
            $display("TESTS FAILED: %0d error(s)", errors);
        $finish;
    end

endmodule
