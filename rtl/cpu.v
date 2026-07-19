// =============================================================================
// cpu.v — Single-cycle RV32I datapath top
// =============================================================================
//
// Wires together: PC, imem, control, immgen, regfile, ALU, dmem, and the
// various muxes (ALU inputs, writeback, next-PC).
//
// One instruction finishes every clock cycle (except when Halt freezes the PC).
//
// =============================================================================

module cpu #(
    parameter IMEM_FILE = "sw/smoke.hex"
) (
    input  wire        clk,
    input  wire        rst,

    // Debug / TB probes
    output wire [31:0] pc_out,
    output wire [31:0] instr,
    output wire        halt
);

    // -------------------------------------------------------------------------
    // Fetch
    // -------------------------------------------------------------------------
    wire [31:0] pc_next;
    wire [31:0] pc_plus4 = pc_out + 32'd4;

    pc u_pc (
        .clk(clk),
        .rst(rst),
        .pc_next(pc_next),
        .pc_out(pc_out)
    );

    imem #(.MEM_FILE(IMEM_FILE)) u_imem (
        .addr(pc_out),
        .instr(instr)
    );

    // Instruction fields
    wire [6:0]  opcode = instr[6:0];
    wire [4:0]  rd     = instr[11:7];
    wire [2:0]  funct3 = instr[14:12];
    wire [4:0]  rs1    = instr[19:15];
    wire [4:0]  rs2    = instr[24:20];
    wire [6:0]  funct7 = instr[31:25];
    wire [11:0] imm12  = instr[31:20];

    // -------------------------------------------------------------------------
    // Control + immediate
    // -------------------------------------------------------------------------
    wire        RegWrite, ALUSrcA, ALUSrcB, MemWrite, MemRead;
    wire        Branch, Jump, JumpReg, Lui;
    wire [2:0]  ImmSrc;
    wire [3:0]  alu_control;
    wire [1:0]  ResultSrc;
    wire [31:0] imm_ext;

    control u_control (
        .opcode(opcode),
        .funct3(funct3),
        .funct7(funct7),
        .imm12(imm12),
        .RegWrite(RegWrite),
        .ImmSrc(ImmSrc),
        .ALUSrcA(ALUSrcA),
        .ALUSrcB(ALUSrcB),
        .alu_control(alu_control),
        .MemWrite(MemWrite),
        .MemRead(MemRead),
        .ResultSrc(ResultSrc),
        .Branch(Branch),
        .Jump(Jump),
        .JumpReg(JumpReg),
        .Lui(Lui),
        .Halt(halt)
    );

    immgen u_immgen (
        .instr(instr),
        .ImmSrc(ImmSrc),
        .imm_ext(imm_ext)
    );

    // -------------------------------------------------------------------------
    // Register file
    // -------------------------------------------------------------------------
    wire [31:0] rd1, rd2, write_data;

    regfile u_rf (
        .clk(clk),
        .rst(rst),
        .we(RegWrite && !halt),
        .ra1(rs1),
        .ra2(rs2),
        .wa(rd),
        .wd(write_data),
        .rd1(rd1),
        .rd2(rd2)
    );

    // -------------------------------------------------------------------------
    // ALU
    // -------------------------------------------------------------------------
    wire [31:0] alu_a = Lui ? 32'b0 : (ALUSrcA ? pc_out : rd1);
    wire [31:0] alu_b = ALUSrcB ? imm_ext : rd2;
    wire [31:0] alu_result;
    wire        zero;

    alu u_alu (
        .a(alu_a),
        .b(alu_b),
        .alu_control(alu_control),
        .result(alu_result),
        .zero(zero)
    );

    // -------------------------------------------------------------------------
    // Data memory
    // -------------------------------------------------------------------------
    wire [31:0] mem_rdata;

    dmem u_dmem (
        .clk(clk),
        .we(MemWrite && !halt),
        .width(funct3),
        .addr(alu_result),
        .wdata(rd2),
        .rdata(mem_rdata)
    );

    // Silence unused MemRead (dmem is always readable combinationally)
    wire _unused_MemRead = MemRead;

    // -------------------------------------------------------------------------
    // Writeback mux
    // -------------------------------------------------------------------------
    assign write_data =
        (ResultSrc == 2'b01) ? mem_rdata :
        (ResultSrc == 2'b10) ? pc_plus4  :
                               alu_result;

    // -------------------------------------------------------------------------
    // Branch decision + next-PC mux
    // -------------------------------------------------------------------------
    wire branch_taken =
        Branch && (
            (funct3 == 3'b000 &&  zero) ||             // BEQ
            (funct3 == 3'b001 && !zero) ||             // BNE
            (funct3 == 3'b100 &&  alu_result[0]) ||    // BLT
            (funct3 == 3'b101 && !alu_result[0]) ||    // BGE
            (funct3 == 3'b110 &&  alu_result[0]) ||    // BLTU
            (funct3 == 3'b111 && !alu_result[0])       // BGEU
        );

    wire [31:0] pc_target_br = pc_out + imm_ext;          // branch / JAL
    wire [31:0] pc_target_jr = alu_result & ~32'd1;       // JALR (clear LSB)

    assign pc_next =
        halt                    ? pc_out       :
        JumpReg                 ? pc_target_jr :
        (Jump || branch_taken)  ? pc_target_br :
                                  pc_plus4;

endmodule
