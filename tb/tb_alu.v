// =============================================================================
// tb_alu.v — Self-checking testbench for the ALU
// =============================================================================
`timescale 1ns/1ps

module tb_alu;

    reg  [31:0] a, b;
    reg  [3:0]  alu_control;
    wire [31:0] result;
    wire        zero;

    integer errors;

    alu uut (
        .a(a), .b(b), .alu_control(alu_control),
        .result(result), .zero(zero)
    );

    task check;
        input [31:0] exp_result;
        input        exp_zero;
        input [255:0] msg;
        begin
            if (result !== exp_result || zero !== exp_zero) begin
                $display("FAIL: %0s - result=0x%08h zero=%b (exp 0x%08h / %b)",
                         msg, result, zero, exp_result, exp_zero);
                errors = errors + 1;
            end else begin
                $display("PASS: %0s", msg);
            end
        end
    endtask

    initial begin
        $dumpfile("tb_alu.vcd");
        $dumpvars(0, tb_alu);
        errors = 0;

        a = 32'd10; b = 32'd3; alu_control = 4'b0000; #1;
        check(32'd13, 1'b0, "ADD 10+3");

        a = 32'd10; b = 32'd10; alu_control = 4'b0001; #1;
        check(32'd0, 1'b1, "SUB equal -> zero");

        a = 32'hF0F0F0F0; b = 32'h0FF00FF0; alu_control = 4'b0010; #1;
        check(32'h00F000F0, 1'b0, "AND");

        a = 32'hF0F0F0F0; b = 32'h0FF00FF0; alu_control = 4'b0011; #1;
        check(32'hFFF0FFF0, 1'b0, "OR");

        a = 32'hF0F0F0F0; b = 32'h0FF00FF0; alu_control = 4'b0100; #1;
        check(32'hFF00FF00, 1'b0, "XOR");

        a = 32'hFFFFFFF0; b = 32'd0; alu_control = 4'b0101; #1; // -16 < 0
        check(32'd1, 1'b0, "SLT signed");

        a = 32'hFFFFFFF0; b = 32'd0; alu_control = 4'b0110; #1; // unsigned large
        check(32'd0, 1'b1, "SLTU unsigned false -> 0");

        a = 32'd1; b = 32'd4; alu_control = 4'b0111; #1;
        check(32'd16, 1'b0, "SLL");

        a = 32'h80000000; b = 32'd4; alu_control = 4'b1000; #1;
        check(32'h08000000, 1'b0, "SRL");

        a = 32'h80000000; b = 32'd4; alu_control = 4'b1001; #1;
        check(32'hF8000000, 1'b0, "SRA");

        if (errors == 0)
            $display("ALL TESTS PASSED");
        else
            $display("TESTS FAILED: %0d error(s)", errors);
        $finish;
    end

endmodule
