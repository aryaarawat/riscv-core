// =============================================================================
// tb_cpu.v — End-to-end smoke test for the single-cycle CPU
// =============================================================================
//
// Loads sw/smoke.hex, runs until Halt (ebreak), then checks that:
//   x3 == 12, x4 == 12, and dmem[0..3] holds little-endian 12.
//
// =============================================================================
`timescale 1ns/1ps

module tb_cpu;

    reg clk, rst;
    wire [31:0] pc_out, instr;
    wire halt;

    integer errors;
    integer cycles;

    cpu #(.IMEM_FILE("sw/smoke.hex")) uut (
        .clk(clk),
        .rst(rst),
        .pc_out(pc_out),
        .instr(instr),
        .halt(halt)
    );

    always #5 clk = ~clk;

    task check32;
        input [31:0] got;
        input [31:0] expected;
        input [255:0] msg;
        begin
            if (got !== expected) begin
                $display("FAIL: %0s - got 0x%08h expected 0x%08h", msg, got, expected);
                errors = errors + 1;
            end else
                $display("PASS: %0s", msg);
        end
    endtask

    initial begin
        $dumpfile("tb_cpu.vcd");
        $dumpvars(0, tb_cpu);

        errors = 0;
        cycles = 0;
        clk = 0;
        rst = 1;

        #12;
        rst = 0;

        // Run until ebreak or timeout
        while (!halt && cycles < 200) begin
            #10;
            cycles = cycles + 1;
        end

        if (!halt) begin
            $display("FAIL: CPU did not hit ebreak within timeout");
            errors = errors + 1;
        end else begin
            $display("PASS: halted on ebreak after %0d cycles", cycles);
        end

        // Hierarchical probes into architectural state
        check32(uut.u_rf.regs[1], 32'd5,  "x1 == 5");
        check32(uut.u_rf.regs[2], 32'd7,  "x2 == 7");
        check32(uut.u_rf.regs[3], 32'd12, "x3 == 12 (add)");
        check32(uut.u_rf.regs[4], 32'd12, "x4 == 12 (load)");

        // dmem little-endian word at address 0
        check32({uut.u_dmem.mem[3], uut.u_dmem.mem[2],
                 uut.u_dmem.mem[1], uut.u_dmem.mem[0]}, 32'd12, "dmem[0] == 12");

        if (errors == 0)
            $display("ALL TESTS PASSED");
        else
            $display("TESTS FAILED: %0d error(s)", errors);
        $finish;
    end

endmodule
