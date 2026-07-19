// =============================================================================
// tb_control.v — Self-checking testbench for the control unit
// =============================================================================
`timescale 1ns/1ps

module tb_control;

    reg  [6:0]  opcode;
    reg  [2:0]  funct3;
    reg  [6:0]  funct7;
    reg  [11:0] imm12;

    wire        RegWrite, ALUSrcA, ALUSrcB, MemWrite, MemRead;
    wire        Branch, Jump, JumpReg, Lui, Halt;
    wire [2:0]  ImmSrc;
    wire [3:0]  alu_control;
    wire [1:0]  ResultSrc;

    integer errors;

    control uut (
        .opcode(opcode), .funct3(funct3), .funct7(funct7), .imm12(imm12),
        .RegWrite(RegWrite), .ImmSrc(ImmSrc), .ALUSrcA(ALUSrcA), .ALUSrcB(ALUSrcB),
        .alu_control(alu_control), .MemWrite(MemWrite), .MemRead(MemRead),
        .ResultSrc(ResultSrc), .Branch(Branch), .Jump(Jump), .JumpReg(JumpReg),
        .Lui(Lui), .Halt(Halt)
    );

    task check1;
        input got;
        input expected;
        input [255:0] msg;
        begin
            if (got !== expected) begin
                $display("FAIL: %0s - got %b expected %b", msg, got, expected);
                errors = errors + 1;
            end else
                $display("PASS: %0s", msg);
        end
    endtask

    task check4;
        input [3:0] got;
        input [3:0] expected;
        input [255:0] msg;
        begin
            if (got !== expected) begin
                $display("FAIL: %0s - got %b expected %b", msg, got, expected);
                errors = errors + 1;
            end else
                $display("PASS: %0s", msg);
        end
    endtask

    initial begin
        $dumpfile("tb_control.vcd");
        $dumpvars(0, tb_control);
        errors = 0;
        funct7 = 0; imm12 = 0; funct3 = 0;

        // ADDI
        opcode = 7'b0010011; funct3 = 3'b000; #1;
        check1(RegWrite, 1, "ADDI RegWrite");
        check1(ALUSrcB, 1, "ADDI ALUSrcB");
        check4(alu_control, 4'b0000, "ADDI -> ADD");

        // SUB
        opcode = 7'b0110011; funct3 = 3'b000; funct7 = 7'b0100000; #1;
        check4(alu_control, 4'b0001, "SUB");
        check1(RegWrite, 1, "SUB RegWrite");

        // LW
        opcode = 7'b0000011; funct3 = 3'b010; funct7 = 0; #1;
        check1(MemRead, 1, "LW MemRead");
        check1(RegWrite, 1, "LW RegWrite");

        // SW
        opcode = 7'b0100011; funct3 = 3'b010; #1;
        check1(MemWrite, 1, "SW MemWrite");
        check1(RegWrite, 0, "SW no RegWrite");

        // BEQ
        opcode = 7'b1100011; funct3 = 3'b000; #1;
        check1(Branch, 1, "BEQ Branch");
        check4(alu_control, 4'b0001, "BEQ -> SUB");

        // JAL
        opcode = 7'b1101111; #1;
        check1(Jump, 1, "JAL Jump");
        check1(RegWrite, 1, "JAL RegWrite");

        // LUI
        opcode = 7'b0110111; #1;
        check1(Lui, 1, "LUI Lui");
        check1(RegWrite, 1, "LUI RegWrite");

        // ebreak
        opcode = 7'b1110011; funct3 = 3'b000; imm12 = 12'd1; #1;
        check1(Halt, 1, "ebreak Halt");

        // ecall should not halt in this core
        imm12 = 12'd0; #1;
        check1(Halt, 0, "ecall no Halt");

        if (errors == 0)
            $display("ALL TESTS PASSED");
        else
            $display("TESTS FAILED: %0d error(s)", errors);
        $finish;
    end

endmodule
