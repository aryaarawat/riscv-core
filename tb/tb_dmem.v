// =============================================================================
// tb_dmem.v — Self-checking testbench for data memory
// =============================================================================
`timescale 1ns/1ps

module tb_dmem;

    reg        clk, we;
    reg  [2:0] width;
    reg  [31:0] addr, wdata;
    wire [31:0] rdata;
    integer errors;

    dmem #(.DEPTH(64)) uut (
        .clk(clk), .we(we), .width(width),
        .addr(addr), .wdata(wdata), .rdata(rdata)
    );

    always #5 clk = ~clk;

    task check;
        input [31:0] expected;
        input [255:0] msg;
        begin
            if (rdata !== expected) begin
                $display("FAIL: %0s - got 0x%08h expected 0x%08h", msg, rdata, expected);
                errors = errors + 1;
            end else
                $display("PASS: %0s", msg);
        end
    endtask

    initial begin
        $dumpfile("tb_dmem.vcd");
        $dumpvars(0, tb_dmem);
        errors = 0;
        clk = 0; we = 0; width = 3'b010; addr = 0; wdata = 0;

        // Store word 0xA1B2C3D4 at address 0
        we = 1; width = 3'b010; addr = 32'd0; wdata = 32'hA1B2C3D4;
        #10;
        we = 0;
        #1;
        check(32'hA1B2C3D4, "LW after SW");

        // LB signed of low byte 0xD4 → sign extend
        width = 3'b000; #1;
        check(32'hFFFFFFD4, "LB sign-extend");

        // LBU
        width = 3'b100; #1;
        check(32'h000000D4, "LBU zero-extend");

        // SB at addr 4, then LB
        we = 1; width = 3'b000; addr = 32'd4; wdata = 32'h0000007F;
        #10;
        we = 0; width = 3'b000; #1;
        check(32'h0000007F, "SB/LB 0x7F");

        // SH then LH
        we = 1; width = 3'b001; addr = 32'd8; wdata = 32'h0000ABCD;
        #10;
        we = 0; width = 3'b001; #1;
        check(32'hFFFFABCD, "SH/LH sign-extend");

        if (errors == 0)
            $display("ALL TESTS PASSED");
        else
            $display("TESTS FAILED: %0d error(s)", errors);
        $finish;
    end

endmodule
