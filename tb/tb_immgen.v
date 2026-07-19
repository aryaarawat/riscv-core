// =============================================================================
// tb_immgen.v — Self-checking testbench for the immediate generator
// =============================================================================
`timescale 1ns/1ps

module tb_immgen;

    reg  [31:0] instr;
    reg  [2:0]  ImmSrc;
    wire [31:0] imm_ext;

    integer errors;

    immgen uut (.instr(instr), .ImmSrc(ImmSrc), .imm_ext(imm_ext));

    task check32;
        input [31:0] expected;
        input [255:0] msg;
        begin
            if (imm_ext !== expected) begin
                $display("FAIL: %0s - got 0x%08h, expected 0x%08h", msg, imm_ext, expected);
                errors = errors + 1;
            end else begin
                $display("PASS: %0s - 0x%08h", msg, imm_ext);
            end
        end
    endtask

    initial begin
        $dumpfile("tb_immgen.vcd");
        $dumpvars(0, tb_immgen);
        errors = 0;

        // I-type: addi x1, x0, -1  → imm = 0xFFFFFFFF
        // opcode=0010011, rd=1, funct3=000, rs1=0, imm=0xFFF
        instr  = 32'hFFF00093;
        ImmSrc = 3'b000;
        #1;
        check32(32'hFFFFFFFF, "I-type -1");

        // I-type positive: addi x1, x0, 42 → imm=42
        instr  = 32'h02A00093;
        ImmSrc = 3'b000;
        #1;
        check32(32'd42, "I-type +42");

        // S-type: sw x1, 4(x2) — imm=4
        // imm[11:5]=0, rs2=1, rs1=2, funct3=010, imm[4:0]=4, opcode=0100011
        instr  = 32'h00112223; // sw x1, 4(x2)
        ImmSrc = 3'b001;
        #1;
        check32(32'd4, "S-type +4");

        // B-type: beq x0, x0, +8 → imm=8 (already *2 in encoding)
        // For offset +8: imm[12|10:5|4:1|11] packed
        // Simplest known encoding: beq x1, x2, 16 → check manually
        // Use: instr with B-imm of +8: bits give imm_ext=8
        // beq x0,x0,8 = 0x00000463
        instr  = 32'h00000463;
        ImmSrc = 3'b010;
        #1;
        check32(32'd8, "B-type +8");

        // U-type: lui x1, 0xABCDE → imm = 0xABCDE000
        instr  = 32'hABCDE0B7;
        ImmSrc = 3'b011;
        #1;
        check32(32'hABCDE000, "U-type LUI");

        // J-type: jal x0, +8 → imm=8
        // jal x0, 8 = 0x0080006F
        instr  = 32'h0080006F;
        ImmSrc = 3'b100;
        #1;
        check32(32'd8, "J-type +8");

        if (errors == 0)
            $display("ALL TESTS PASSED");
        else
            $display("TESTS FAILED: %0d error(s)", errors);
        $finish;
    end

endmodule
