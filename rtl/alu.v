// =============================================================================
// alu.v — RV32I arithmetic / logic unit
// =============================================================================
//
// Computes result = f(a, b) based on alu_control. Also raises `zero` when the
// result is all zeros (used by BEQ/BNE after a subtract).
//
// alu_control encoding:
//   4'b0000  ADD
//   4'b0001  SUB
//   4'b0010  AND
//   4'b0011  OR
//   4'b0100  XOR
//   4'b0101  SLT   (signed less-than → 1 or 0)
//   4'b0110  SLTU  (unsigned less-than)
//   4'b0111  SLL   (shift left logical; shift amount = b[4:0])
//   4'b1000  SRL   (shift right logical)
//   4'b1001  SRA   (shift right arithmetic)
//
// =============================================================================

module alu (
    input  wire [31:0] a,
    input  wire [31:0] b,
    input  wire [3:0]  alu_control,
    output reg  [31:0] result,
    output wire        zero
);

    // Signed views for SLT / SRA
    wire signed [31:0] a_s = a;
    wire signed [31:0] b_s = b;

    always @(*) begin
        case (alu_control)
            4'b0000: result = a + b;
            4'b0001: result = a - b;
            4'b0010: result = a & b;
            4'b0011: result = a | b;
            4'b0100: result = a ^ b;
            4'b0101: result = (a_s < b_s) ? 32'd1 : 32'd0;
            4'b0110: result = (a < b)     ? 32'd1 : 32'd0;
            4'b0111: result = a << b[4:0];
            4'b1000: result = a >> b[4:0];
            4'b1001: result = a_s >>> b[4:0];
            default: result = 32'b0;
        endcase
    end

    assign zero = (result == 32'b0);

endmodule
