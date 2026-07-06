`timescale 1ns/1ps

module tb_pc;

    reg clk;
    reg rst;
    reg [31:0] pc_next;
    wire [31:0] pc_out;

    pc uut (
        .clk(clk),
        .rst(rst),
        .pc_next(pc_next),
        .pc_out(pc_out)
    );

    always #5 clk = ~clk;

    initial begin
        $dumpfile("tb_pc.vcd");
        $dumpvars(0, tb_pc);

        clk = 0;
        rst = 1;
        pc_next = 32'd0;
        #10;

        rst = 0;
        pc_next = 32'd4;
        #10;

        pc_next = 32'd8;
        #10;

        pc_next = 32'd100;
        #10;

        $display("Final PC value: %0d", pc_out);
        $finish;
    end

endmodule