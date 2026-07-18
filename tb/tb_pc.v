`timescale 1ns/1ps

module tb_pc;

    reg clk;
    reg rst;
    reg [31:0] pc_next;
    wire [31:0] pc_out;

    integer errors;

    pc uut (
        .clk(clk),
        .rst(rst),
        .pc_next(pc_next),
        .pc_out(pc_out)
    );

    always #5 clk = ~clk;

    task check;
        input [31:0] expected;
        input [255:0] msg;
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

    initial begin
        $dumpfile("tb_pc.vcd");
        $dumpvars(0, tb_pc);

        errors = 0;
        clk = 0;
        rst = 1;
        pc_next = 32'd0;

        // Hold reset for one full clock edge
        #12;
        check(32'd0, "reset forces PC to 0");

        // Normal increments
        rst = 0;
        pc_next = 32'd4;
        #10;
        check(32'd4, "PC loads 4");

        pc_next = 32'd8;
        #10;
        check(32'd8, "PC loads 8");

        pc_next = 32'd100;
        #10;
        check(32'd100, "PC loads 100");

        // Reset asserted mid-run (asynchronous)
        rst = 1;
        #1;
        check(32'd0, "mid-run reset clears PC");

        // Release reset; next edge should load pc_next
        rst = 0;
        pc_next = 32'd200;
        #10;
        check(32'd200, "PC recovers after reset");

        if (errors == 0)
            $display("ALL TESTS PASSED");
        else
            $display("TESTS FAILED: %0d error(s)", errors);

        $finish;
    end

endmodule
