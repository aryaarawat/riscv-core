// =============================================================================
// tb_regfile.v — Self-checking testbench for the register file
// =============================================================================
`timescale 1ns/1ps

module tb_regfile;

    reg clk, rst, we;
    reg [4:0] ra1, ra2, wa;
    reg [31:0] wd;
    wire [31:0] rd1, rd2;

    integer errors;

    regfile uut (
        .clk(clk), .rst(rst), .we(we),
        .ra1(ra1), .ra2(ra2), .wa(wa), .wd(wd),
        .rd1(rd1), .rd2(rd2)
    );

    always #5 clk = ~clk;

    task check32;
        input [31:0] got;
        input [31:0] expected;
        input [255:0] msg;
        begin
            if (got !== expected) begin
                $display("FAIL: %0s - got 0x%08h, expected 0x%08h", msg, got, expected);
                errors = errors + 1;
            end else begin
                $display("PASS: %0s - 0x%08h", msg, got);
            end
        end
    endtask

    initial begin
        $dumpfile("tb_regfile.vcd");
        $dumpvars(0, tb_regfile);

        errors = 0;
        clk = 0; rst = 1; we = 0;
        ra1 = 0; ra2 = 0; wa = 0; wd = 0;

        #12;
        check32(rd1, 32'd0, "reset: x0 read is 0");
        ra1 = 5'd5;
        #1;
        check32(rd1, 32'd0, "reset: x5 cleared");

        // Write x5 = 0xDEADBEEF
        rst = 0;
        we = 1; wa = 5'd5; wd = 32'hDEADBEEF;
        #10;
        we = 0;
        ra1 = 5'd5; ra2 = 5'd0;
        #1;
        check32(rd1, 32'hDEADBEEF, "read back x5");
        check32(rd2, 32'd0, "x0 still 0 after write to x5");

        // Attempt write to x0 — must be ignored
        we = 1; wa = 5'd0; wd = 32'hFFFFFFFF;
        #10;
        we = 0;
        ra1 = 5'd0;
        #1;
        check32(rd1, 32'd0, "write to x0 ignored");

        // Dual read: write x7, read x5 and x7 together
        we = 1; wa = 5'd7; wd = 32'h11112222;
        #10;
        we = 0;
        ra1 = 5'd5; ra2 = 5'd7;
        #1;
        check32(rd1, 32'hDEADBEEF, "dual-read port1 x5");
        check32(rd2, 32'h11112222, "dual-read port2 x7");

        // Mid-run async reset
        rst = 1;
        #1;
        ra1 = 5'd5;
        #1;
        check32(rd1, 32'd0, "mid-run reset clears x5");

        if (errors == 0)
            $display("ALL TESTS PASSED");
        else
            $display("TESTS FAILED: %0d error(s)", errors);
        $finish;
    end

endmodule
