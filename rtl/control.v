// =============================================================================
// control.v — Main control decoder for single-cycle RV32I
// =============================================================================
//
// Looks at opcode / funct3 / funct7 (/ imm12 for SYSTEM) and produces the mux
// selects and enables that steer the datapath for one instruction per cycle.
//
// ImmSrc:    000=I  001=S  010=B  011=U  100=J
// ResultSrc: 00=ALU  01=DMEM  10=PC+4
// ALUSrcA:   0=rs1  1=PC     (AUIPC). LUI forces ALU A=0 in cpu.v
// ALUSrcB:   0=rs2  1=imm
//
// alu_control matches alu.v encodings.
// Branch taken decision (BEQ vs BNE vs BLT ...) is finalized in cpu.v using
// funct3 + ALU result/zero.
//
// =============================================================================

module control (
    input  wire [6:0]  opcode,
    input  wire [2:0]  funct3,
    input  wire [6:0]  funct7,
    input  wire [11:0] imm12,      // instr[31:20] — needed to spot ebreak

    output reg         RegWrite,
    output reg [2:0]   ImmSrc,
    output reg         ALUSrcA,
    output reg         ALUSrcB,
    output reg [3:0]   alu_control,
    output reg         MemWrite,
    output reg         MemRead,
    output reg [1:0]   ResultSrc,
    output reg         Branch,
    output reg         Jump,       // JAL
    output reg         JumpReg,    // JALR
    output reg         Lui,        // force ALU A = 0
    output reg         Halt        // ebreak — stop simulation
);

    localparam OP_LUI    = 7'b0110111;
    localparam OP_AUIPC  = 7'b0010111;
    localparam OP_JAL    = 7'b1101111;
    localparam OP_JALR   = 7'b1100111;
    localparam OP_BRANCH = 7'b1100011;
    localparam OP_LOAD   = 7'b0000011;
    localparam OP_STORE  = 7'b0100011;
    localparam OP_OPIMM  = 7'b0010011;
    localparam OP_OP     = 7'b0110011;
    localparam OP_SYSTEM = 7'b1110011;

    function [3:0] alu_from_funct;
        input [2:0] f3;
        input [6:0] f7;
        input       is_reg_op;
        begin
            case (f3)
                3'b000: alu_from_funct = (is_reg_op && f7[5]) ? 4'b0001 : 4'b0000;
                3'b001: alu_from_funct = 4'b0111;
                3'b010: alu_from_funct = 4'b0101;
                3'b011: alu_from_funct = 4'b0110;
                3'b100: alu_from_funct = 4'b0100;
                3'b101: alu_from_funct = f7[5] ? 4'b1001 : 4'b1000;
                3'b110: alu_from_funct = 4'b0011;
                3'b111: alu_from_funct = 4'b0010;
                default: alu_from_funct = 4'b0000;
            endcase
        end
    endfunction

    function [3:0] alu_for_branch;
        input [2:0] f3;
        begin
            case (f3)
                3'b000, 3'b001: alu_for_branch = 4'b0001; // SUB
                3'b100, 3'b101: alu_for_branch = 4'b0101; // SLT
                3'b110, 3'b111: alu_for_branch = 4'b0110; // SLTU
                default:        alu_for_branch = 4'b0001;
            endcase
        end
    endfunction

    always @(*) begin
        RegWrite    = 1'b0;
        ImmSrc      = 3'b000;
        ALUSrcA     = 1'b0;
        ALUSrcB     = 1'b0;
        alu_control = 4'b0000;
        MemWrite    = 1'b0;
        MemRead     = 1'b0;
        ResultSrc   = 2'b00;
        Branch      = 1'b0;
        Jump        = 1'b0;
        JumpReg     = 1'b0;
        Lui         = 1'b0;
        Halt        = 1'b0;

        case (opcode)
            OP_LUI: begin
                RegWrite    = 1'b1;
                ImmSrc      = 3'b011;
                ALUSrcB     = 1'b1;
                alu_control = 4'b0000;
                Lui         = 1'b1;
            end

            OP_AUIPC: begin
                RegWrite    = 1'b1;
                ImmSrc      = 3'b011;
                ALUSrcA     = 1'b1;
                ALUSrcB     = 1'b1;
                alu_control = 4'b0000;
            end

            OP_JAL: begin
                RegWrite  = 1'b1;
                ImmSrc    = 3'b100;
                ResultSrc = 2'b10;
                Jump      = 1'b1;
            end

            OP_JALR: begin
                RegWrite    = 1'b1;
                ImmSrc      = 3'b000;
                ALUSrcB     = 1'b1;
                alu_control = 4'b0000;
                ResultSrc   = 2'b10;
                JumpReg     = 1'b1;
            end

            OP_BRANCH: begin
                ImmSrc      = 3'b010;
                alu_control = alu_for_branch(funct3);
                Branch      = 1'b1;
            end

            OP_LOAD: begin
                RegWrite    = 1'b1;
                ImmSrc      = 3'b000;
                ALUSrcB     = 1'b1;
                alu_control = 4'b0000;
                MemRead     = 1'b1;
                ResultSrc   = 2'b01;
            end

            OP_STORE: begin
                ImmSrc      = 3'b001;
                ALUSrcB     = 1'b1;
                alu_control = 4'b0000;
                MemWrite    = 1'b1;
            end

            OP_OPIMM: begin
                RegWrite    = 1'b1;
                ImmSrc      = 3'b000;
                ALUSrcB     = 1'b1;
                alu_control = alu_from_funct(funct3, funct7, 1'b0);
            end

            OP_OP: begin
                RegWrite    = 1'b1;
                alu_control = alu_from_funct(funct3, funct7, 1'b1);
            end

            OP_SYSTEM: begin
                // ebreak = imm12==1, funct3==0
                if (funct3 == 3'b000 && imm12 == 12'd1)
                    Halt = 1'b1;
            end

            default: ;
        endcase
    end

endmodule
