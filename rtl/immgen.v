// =============================================================================
// immgen.v — RISC-V immediate generator
// =============================================================================
//
// Different instruction formats pack the immediate into different bits of the
// 32-bit instruction word. This module extracts and sign-extends (or zero-
// pads for U-type) the immediate based on ImmSrc from the control unit.
//
// ImmSrc encoding used in this core:
//   3'b000  I-type  (ADDI, loads, JALR, ...)
//   3'b001  S-type  (stores)
//   3'b010  B-type  (branches) — note: already shifted left by 1 in encoding
//   3'b011  U-type  (LUI, AUIPC) — upper 20 bits, lower 12 zero
//   3'b100  J-type  (JAL) — note: already shifted left by 1 in encoding
//
// =============================================================================

module immgen (
    input  wire [31:0] instr,
    input  wire [2:0]  ImmSrc,
    output reg  [31:0] imm_ext
);

    always @(*) begin
        case (ImmSrc)
            // I-type: instr[31:20], sign-extended
            3'b000: imm_ext = {{20{instr[31]}}, instr[31:20]};

            // S-type: {instr[31:25], instr[11:7]}, sign-extended
            3'b001: imm_ext = {{20{instr[31]}}, instr[31:25], instr[11:7]};

            // B-type: {instr[31], instr[7], instr[30:25], instr[11:8], 1'b0}
            3'b010: imm_ext = {{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0};

            // U-type: {instr[31:12], 12'b0}
            3'b011: imm_ext = {instr[31:12], 12'b0};

            // J-type: {instr[31], instr[19:12], instr[20], instr[30:21], 1'b0}
            3'b100: imm_ext = {{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0};

            default: imm_ext = 32'b0;
        endcase
    end

endmodule
