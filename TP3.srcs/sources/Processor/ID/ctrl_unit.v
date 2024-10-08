`timescale 1ns / 1ps

/*
Se define la unidad de registros de control. Es responsable de generar las señales de control 
necesarias para cada instrucción, basándose en en los codigos de la instrucción
*/

module ctrl_register
    #(
        // I TYPE
        parameter OPP_LB     = 6'b100000,
        parameter OPP_LH     = 6'b100001,
        parameter OPP_LW     = 6'b100011,
        parameter OPP_LWU    = 6'b100111,
        parameter OPP_LBU    = 6'b100100,
        parameter OPP_LHU    = 6'b100101,
        parameter OPP_SB     = 6'b101000,
        parameter OPP_SH     = 6'b101001,
        parameter OPP_SW     = 6'b101011,
        parameter OPP_ADDI   = 6'b001000,
        parameter OPP_ANDI   = 6'b001100,
        parameter OPP_ORI    = 6'b001101,
        parameter OPP_XORI   = 6'b001110,
        parameter OPP_LUI    = 6'b001111,
        parameter OPP_SLTI   = 6'b001010,
        parameter OPP_BEQ    = 6'b000100,
        parameter OPP_BNE    = 6'b000101,
        parameter OPP_J      = 6'b000010,
        parameter OPP_JAL    = 6'b000011,

        parameter OPP_R_TYPE = 6'b000000, 
        // R TYPE
        parameter FUNCT_SLL  = 6'b000000,
        parameter FUNCT_SRL  = 6'b000010,
        parameter FUNCT_SRA  = 6'b000011,

        // J TYPE
        parameter FUNCT_JR   = 6'b001000,
        parameter FUNCT_JALR = 6'b001001,

        // CONTROL PARAMETERS
        // PC
        parameter CTRL_NEXT_PC_SRC_SEQ = 1'b0  , // Sequential
        parameter CTRL_NEXT_PC_SRC_NOT_SEQ = 1'b1  , // Not sequential

        // JUMP
        parameter CTRL_NOT_JMP = 2'bxx , // Not jump
        parameter CTRL_JMP_DIR = 2'b10 , // Jump direct
        parameter CTRL_JMP_REG = 2'b01 , // Jump register
        parameter CTRL_JMP_BRANCH = 2'b00 , // Jump branch

        // REGISTER DESTINATION
        parameter CTRL_REG_DST_RD = 2'b01 , // Register destination is rd
        parameter CTRL_REG_DST_GPR_31 = 2'b10 , // Register destination is gpr[31]
        parameter CTRL_REG_DST_RT = 2'b00 , // Register destination is rt
        parameter CTRL_REG_DST_NOTHING = 2'bxx , // Register destination is nothing

        // MEMORY WRITE SOURCE
        parameter CTRL_MEM_WR_SRC_WORD = 2'b00 , // Memory write source is word
        parameter CTRL_MEM_WR_SRC_HALFWORD = 2'b01 , // Memory write source is halfword
        parameter CTRL_MEM_WR_SRC_BYTE = 2'b10 , // Memory write source is byte
        parameter CTRL_MEM_WR_SRC_NOTHING = 2'bxx , // Memory write source is nothing

        // MEMORY READ SOURCE
        parameter CTRL_MEM_RD_SRC_WORD = 3'b000, // Memory read source is word
        parameter CTRL_MEM_RD_SRC_SIG_HALFWORD = 3'b001, // Memory read source is signed halfword
        parameter CTRL_MEM_RD_SRC_SIG_BYTE = 3'b010, // Memory read source is signed byte
        parameter CTRL_MEM_RD_SRC_USIG_HALFWORD = 3'b011, // Memory read source is unsigned halfword
        parameter CTRL_MEM_RD_SRC_USIG_BYTE = 3'b100, // Memory read source is unsigned byte
        parameter CTRL_MEM_RD_SRC_NOTHING = 3'bxxx, // Memory read source is nothing

        // MEMORY WRITE
        parameter CTRL_MEM_WRITE_ENABLE = 1'b1  , // Enable memory write
        parameter CTRL_MEM_WRITE_DISABLE = 1'b0  , // Disable memory write

        // WRITE BACK
        parameter CTRL_WB_ENABLE = 1'b1  , // Enable register write back
        parameter CTRL_WB_DISABLE = 1'b0  , // Disable register write back
        parameter CTRL_MEM_TO_REG_MEM_RESULT = 1'b0  , // Memory result to register
        parameter CTRL_MEM_TO_REG_ALU_RESULT = 1'b1  , // ALU result to register
        parameter CTRL_MEM_TO_REG_NOTHING = 1'bx  , // Nothing to register

        // ALU control parameters
        parameter ALU_CTRL_LOAD_TYPE = 3'b000, // Load instructions
        parameter ALU_CTRL_STORE_TYPE = 3'b000, // Store instructions
        parameter ALU_CTRL_ADDI = 3'b000, // Add immediate instruction
        parameter ALU_CTRL_BRANCH_TYPE = 3'b001, // Branch instructions
        parameter ALU_CTRL_ANDI = 3'b010, // And immediate instruction
        parameter ALU_CTRL_ORI = 3'b011, // Or immediate instruction
        parameter ALU_CTRL_XORI = 3'b100, // Xor immediate instruction
        parameter ALU_CTRL_SLTI = 3'b101, // Set less than immediate instruction
        parameter ALU_CTRL_R_TYPE = 3'b110, // R-Type instructions
        parameter ALU_CTRL_JUMP_TYPE = 3'b111, // Jump instructions
        parameter ALU_CTRL_UNDEFINED = 3'bxxx, // Undefined instruction
        parameter ALU_CTRL_SRC_A_SHAMT = 1'b0 , // Shamt
        parameter ALU_CTRL_SRC_A_BUS_A = 1'b1 , // Bus A
        parameter ALU_CTRL_SRC_A_NOTHING = 1'bx, // Nothing    
        parameter ALU_CTRL_SRC_B_NEXT_SEQ_PC = 3'b000 , // Next sequential PC
        parameter ALU_CTRL_SRC_B_UPPER_INM = 3'b001 , // Upper immediate
        parameter ALU_CTRL_SRC_B_SIG_INM = 3'b010 , // Sign immediate
        parameter ALU_CTRL_SRC_B_USIG_INM = 3'b011 , // Unsigned immediate
        parameter ALU_CTRL_SRC_B_BUS_B = 3'b100 , // Bus B
        parameter ALU_CTRL_SRC_B_NOTHING = 3'bxxx // Nothing
    )
    (
        input  wire i_are_equal, // is bus A different from bus B?
        input  wire i_instr_nop, // is nop?
        input  wire [5 : 0]  i_opp,
        input  wire [5 : 0]  i_funct,
        output wire [19 : 0] o_ctrl_register
    );

    reg [19 : 0] ctrl_register; 
    // reg next_pc_src;
    // reg [1 : 0] jmp_ctrl;
    // reg [1 : 0] reg_dst;
    // reg alu_src_A;
    // reg [2 : 0] alu_src_B;
    // reg [2 : 0] alu_opp;
    // reg [2 : 0] mem_read_source;
    // reg [1 : 0] mem_write_source;
    // reg mem_write;
    // reg wb;
    // reg mem_to_reg;

    always @(*) begin
    //     if (!i_instr_nop)
    //         case(i_opp)
    //             OPP_R_TYPE : begin
    //                 mem_read_source <= CTRL_MEM_RD_SRC_NOTHING;
    //                 mem_write_source <= CTRL_MEM_WR_SRC_NOTHING;
    //                 alu_opp <= ALU_CTRL_R_TYPE;
    //                 mem_write <= CTRL_MEM_WRITE_DISABLE;

    //                 case(i_funct)
    //                     FUNCT_JR : begin
    //                         next_pc_src <= CTRL_NEXT_PC_SRC_NOT_SEQ;
    //                         jmp_ctrl <= CTRL_JMP_REG;
    //                         reg_dst <= CTRL_REG_DST_NOTHING;
    //                         alu_src_A <= ALU_CTRL_SRC_A_NOTHING;
    //                         alu_src_B <= ALU_CTRL_SRC_B_NOTHING;
    //                         wb <= CTRL_WB_DISABLE;
    //                         mem_to_reg <= CTRL_MEM_TO_REG_NOTHING;
    //                         ctrl_register = {next_pc_src, jmp_ctrl, reg_dst, alu_src_A, alu_src_B, alu_opp, mem_read_source, mem_write_source, mem_write, wb, mem_to_reg};
    //                     end
    //                     FUNCT_JALR : begin
    //                         next_pc_src <= CTRL_NEXT_PC_SRC_NOT_SEQ;
    //                         jmp_ctrl <= CTRL_JMP_REG;
    //                         reg_dst <= CTRL_REG_DST_GPR_31;
    //                         alu_src_A <= ALU_CTRL_SRC_A_BUS_A;
    //                         alu_src_B <= ALU_CTRL_SRC_B_NEXT_SEQ_PC;
    //                         wb <= CTRL_WB_ENABLE;
    //                         mem_to_reg <= CTRL_MEM_TO_REG_ALU_RESULT;
    //                         ctrl_register = {next_pc_src, jmp_ctrl, reg_dst, alu_src_A, alu_src_B, alu_opp, mem_read_source, mem_write_source, mem_write, wb, mem_to_reg};
    //                     end
    //                     FUNCT_SLL : begin
    //                         next_pc_src <= CTRL_NEXT_PC_SRC_SEQ;
    //                         jmp_ctrl <= CTRL_NOT_JMP;
    //                         reg_dst <= CTRL_REG_DST_RD;
    //                         alu_src_A <= ALU_CTRL_SRC_A_SHAMT;
    //                         alu_src_B <= ALU_CTRL_SRC_B_BUS_B;
    //                         wb <= CTRL_WB_ENABLE;
    //                         mem_to_reg <= CTRL_MEM_TO_REG_ALU_RESULT;
    //                         ctrl_register = {next_pc_src, jmp_ctrl, reg_dst, alu_src_A, alu_src_B, alu_opp, mem_read_source, mem_write_source, mem_write, wb, mem_to_reg};
    //                     end
    //                     FUNCT_SRL : begin
    //                         next_pc_src <= CTRL_NEXT_PC_SRC_SEQ;
    //                         jmp_ctrl <= CTRL_NOT_JMP;
    //                         reg_dst <= CTRL_REG_DST_RD;
    //                         alu_src_A <= ALU_CTRL_SRC_A_SHAMT;
    //                         alu_src_B <= ALU_CTRL_SRC_B_BUS_B;
    //                         wb <= CTRL_WB_ENABLE;
    //                         mem_to_reg <= CTRL_MEM_TO_REG_ALU_RESULT;
    //                         ctrl_register = {next_pc_src, jmp_ctrl, reg_dst, alu_src_A, alu_src_B, alu_opp, mem_read_source, mem_write_source, mem_write, wb, mem_to_reg};
    //                     end
    //                     FUNCT_SRA : begin
    //                         next_pc_src <= CTRL_NEXT_PC_SRC_SEQ;
    //                         jmp_ctrl <= CTRL_NOT_JMP;
    //                         reg_dst <= CTRL_REG_DST_RD;
    //                         alu_src_A <= ALU_CTRL_SRC_A_SHAMT;
    //                         alu_src_B <= ALU_CTRL_SRC_B_BUS_B;
    //                         wb <= CTRL_WB_ENABLE;
    //                         mem_to_reg <= CTRL_MEM_TO_REG_ALU_RESULT;
    //                         ctrl_register = {next_pc_src, jmp_ctrl, reg_dst, alu_src_A, alu_src_B, alu_opp, mem_read_source, mem_write_source, mem_write, wb, mem_to_reg};
    //                     end
    //                     default : begin
    //                         next_pc_src <= CTRL_NEXT_PC_SRC_SEQ;
    //                         jmp_ctrl <= CTRL_NOT_JMP;
    //                         reg_dst <= CTRL_REG_DST_RD;
    //                         alu_src_A <= ALU_CTRL_SRC_A_BUS_A;
    //                         alu_src_B <= ALU_CTRL_SRC_B_BUS_B;
    //                         wb <= CTRL_WB_ENABLE;
    //                         mem_to_reg <= CTRL_MEM_TO_REG_ALU_RESULT;
    //                         ctrl_register = {next_pc_src, jmp_ctrl, reg_dst, alu_src_A, alu_src_B, alu_opp, mem_read_source, mem_write_source, mem_write, wb, mem_to_reg};
    //                     end
    //                 endcase
    //             end
    //             OPP_LW : begin
    //                 next_pc_src <= CTRL_NEXT_PC_SRC_SEQ;
    //                 jmp_ctrl <= CTRL_NOT_JMP;
    //                 reg_dst <= CTRL_REG_DST_RT;
    //                 alu_src_A <= ALU_CTRL_SRC_A_BUS_A;
    //                 alu_src_B <= ALU_CTRL_SRC_B_SIG_INM;
    //                 alu_opp <= ALU_CTRL_LOAD_TYPE;
    //                 mem_read_source <= CTRL_MEM_RD_SRC_WORD;
    //                 mem_write_source <= CTRL_MEM_WR_SRC_NOTHING;
    //                 mem_write <= CTRL_MEM_WRITE_DISABLE;
    //                 wb <= CTRL_WB_ENABLE;
    //                 mem_to_reg <= CTRL_MEM_TO_REG_MEM_RESULT;
    //                 ctrl_register = {next_pc_src, jmp_ctrl, reg_dst, alu_src_A, alu_src_B, alu_opp, mem_read_source, mem_write_source, mem_write, wb, mem_to_reg};
    //             end
    //             OPP_SW : begin
    //                 next_pc_src <= CTRL_NEXT_PC_SRC_SEQ;
    //                 jmp_ctrl <= CTRL_NOT_JMP;
    //                 reg_dst <= CTRL_REG_DST_NOTHING;
    //                 alu_src_A <= ALU_CTRL_SRC_A_BUS_A;
    //                 alu_src_B <= ALU_CTRL_SRC_B_SIG_INM;
    //                 alu_opp <= ALU_CTRL_STORE_TYPE;
    //                 mem_read_source <= CTRL_MEM_RD_SRC_NOTHING;
    //                 mem_write_source <= CTRL_MEM_WR_SRC_WORD;
    //                 mem_write <= CTRL_MEM_WRITE_ENABLE;
    //                 wb <= CTRL_WB_DISABLE;
    //                 mem_to_reg <= CTRL_MEM_TO_REG_NOTHING;
    //                 ctrl_register = {next_pc_src, jmp_ctrl, reg_dst, alu_src_A, alu_src_B, alu_opp, mem_read_source, mem_write_source, mem_write, wb, mem_to_reg};
    //             end
    //             OPP_BEQ : begin
    //                 next_pc_src <= i_are_equal ? CTRL_NEXT_PC_SRC_NOT_SEQ : CTRL_NEXT_PC_SRC_SEQ, CTRL_NOT_JMP;
    //                 jmp_ctrl <= i_are_equal ? CTRL_JMP_BRANCH : CTRL_NOT_JMP;
    //                 reg_dst <= CTRL_REG_DST_NOTHING;
    //                 alu_src_A <= ALU_CTRL_SRC_A_NOTHING;
    //                 alu_src_B <= ALU_CTRL_SRC_B_NOTHING;
    //                 alu_opp <= ALU_CTRL_BRANCH_TYPE;
    //                 mem_read_source <= CTRL_MEM_RD_SRC_NOTHING;
    //                 mem_write_source <= CTRL_MEM_WR_SRC_NOTHING;
    //                 mem_write <= CTRL_MEM_WRITE_DISABLE;
    //                 wb <= CTRL_WB_DISABLE;
    //                 mem_to_reg <= CTRL_MEM_TO_REG_NOTHING;
    //                 ctrl_register = {next_pc_src, jmp_ctrl, reg_dst, alu_src_A, alu_src_B, alu_opp, mem_read_source, mem_write_source, mem_write, wb, mem_to_reg};
    //             end
    //             OPP_BNE : begin
    //                 next_pc_src <= !i_are_equal ? CTRL_NEXT_PC_SRC_NOT_SEQ : CTRL_NEXT_PC_SRC_SEQ;
    //                 jmp_ctrl <= !i_are_equal ? CTRL_JMP_BRANCH : CTRL_NOT_JMP;
    //                 reg_dst <= CTRL_REG_DST_NOTHING;
    //                 alu_src_A <= ALU_CTRL_SRC_A_NOTHING;
    //                 alu_src_B <= ALU_CTRL_SRC_B_NOTHING;
    //                 alu_opp <= ALU_CTRL_BRANCH_TYPE;
    //                 mem_read_source <= CTRL_MEM_RD_SRC_NOTHING;
    //                 mem_write_source <= CTRL_MEM_WR_SRC_NOTHING;
    //                 mem_write <= CTRL_MEM_WRITE_DISABLE;
    //                 wb <= CTRL_WB_DISABLE;
    //                 mem_to_reg <= CTRL_MEM_TO_REG_NOTHING;
    //                 ctrl_register = {next_pc_src, jmp_ctrl, reg_dst, alu_src_A, alu_src_B, alu_opp, mem_read_source, mem_write_source, mem_write, wb, mem_to_reg};
    //             end
    //             OPP_ADDI : begin
    //                 next_pc_src <= CTRL_NEXT_PC_SRC_SEQ;
    //                 jmp_ctrl <= CTRL_NOT_JMP;
    //                 reg_dst <= CTRL_REG_DST_RT;
    //                 alu_src_A <= ALU_CTRL_SRC_A_BUS_A;
    //                 alu_src_B <= ALU_CTRL_SRC_B_SIG_INM;
    //                 alu_opp <= ALU_CTRL_ADDI;
    //                 mem_read_source <= CTRL_MEM_RD_SRC_NOTHING;
    //                 mem_write_source <= CTRL_MEM_WR_SRC_NOTHING;
    //                 mem_write <= CTRL_MEM_WRITE_DISABLE;
    //                 wb <= CTRL_WB_ENABLE;
    //                 mem_to_reg <= CTRL_MEM_TO_REG_ALU_RESULT;
    //                 ctrl_register = {next_pc_src, jmp_ctrl, reg_dst, alu_src_A, alu_src_B, alu_opp, mem_read_source, mem_write_source, mem_write, wb, mem_to_reg};
    //             end
    //             OPP_J : begin
    //                 next_pc_src <= CTRL_NEXT_PC_SRC_NOT_SEQ;
    //                 jmp_ctrl <= CTRL_JMP_DIR;
    //                 reg_dst <= CTRL_REG_DST_NOTHING;
    //                 alu_src_A <= ALU_CTRL_SRC_A_NOTHING;
    //                 alu_src_B <= ALU_CTRL_SRC_B_NOTHING;
    //                 alu_opp <= ALU_CTRL_JUMP_TYPE;
    //                 mem_read_source <= CTRL_MEM_RD_SRC_NOTHING;
    //                 mem_write_source <= CTRL_MEM_WR_SRC_NOTHING;
    //                 mem_write <= CTRL_MEM_WRITE_DISABLE;
    //                 wb <= CTRL_WB_DISABLE;
    //                 mem_to_reg <= CTRL_MEM_TO_REG_NOTHING;
    //                 ctrl_register = {next_pc_src, jmp_ctrl, reg_dst, alu_src_A, alu_src_B, alu_opp, mem_read_source, mem_write_source, mem_write, wb, mem_to_reg};
    //             end
    //             OPP_JAL : begin
    //                 next_pc_src <= CTRL_NEXT_PC_SRC_NOT_SEQ;
    //                 jmp_ctrl <= CTRL_JMP_DIR;
    //                 reg_dst <= CTRL_REG_DST_GPR_31;
    //                 alu_src_A <= ALU_CTRL_SRC_A_NOTHING;
    //                 alu_src_B <= ALU_CTRL_SRC_B_NEXT_SEQ_PC;
    //                 alu_opp <= ALU_CTRL_JUMP_TYPE;
    //                 mem_read_source <= CTRL_MEM_RD_SRC_NOTHING;
    //                 mem_write_source <= CTRL_MEM_WR_SRC_NOTHING;
    //                 mem_write <= CTRL_MEM_WRITE_DISABLE;
    //                 wb <= CTRL_WB_ENABLE;
    //                 mem_to_reg <= CTRL_MEM_TO_REG_ALU_RESULT;
    //                 ctrl_register = {next_pc_src, jmp_ctrl, reg_dst, alu_src_A, alu_src_B, alu_opp, mem_read_source, mem_write_source, mem_write, wb, mem_to_reg};
    //             end
    //             OPP_ANDI : begin
    //                 next_pc_src <= CTRL_NEXT_PC_SRC_SEQ;
    //                 jmp_ctrl <= CTRL_NOT_JMP;
    //                 reg_dst <= CTRL_REG_DST_RT;
    //                 alu_src_A <= ALU_CTRL_SRC_A_BUS_A;
    //                 alu_src_B <= ALU_CTRL_SRC_B_USIG_INM;
    //                 alu_opp <= ALU_CTRL_ANDI;
    //                 mem_read_source <= CTRL_MEM_RD_SRC_NOTHING;
    //                 mem_write_source <= CTRL_MEM_WR_SRC_NOTHING;
    //                 mem_write <= CTRL_MEM_WRITE_DISABLE;
    //                 wb <= CTRL_WB_ENABLE;
    //                 mem_to_reg <= CTRL_MEM_TO_REG_ALU_RESULT;
    //                 ctrl_register = {next_pc_src, jmp_ctrl, reg_dst, alu_src_A, alu_src_B, alu_opp, mem_read_source, mem_write_source, mem_write, wb, mem_to_reg};
    //             end
    //             OPP_ORI : begin
    //                 next_pc_src <= CTRL_NEXT_PC_SRC_SEQ;
    //                 jmp_ctrl <= CTRL_NOT_JMP;
    //                 reg_dst <= CTRL_REG_DST_RT;
    //                 alu_src_A <= ALU_CTRL_SRC_A_BUS_A;
    //                 alu_src_B <= ALU_CTRL_SRC_B_USIG_INM;
    //                 alu_opp <= ALU_CTRL_ORI;
    //                 mem_read_source <= CTRL_MEM_RD_SRC_NOTHING;
    //                 mem_write_source <= CTRL_MEM_WR_SRC_NOTHING;
    //                 mem_write <= CTRL_MEM_WRITE_DISABLE;
    //                 wb <= CTRL_WB_ENABLE;
    //                 mem_to_reg <= CTRL_MEM_TO_REG_ALU_RESULT;
    //                 ctrl_register = {next_pc_src, jmp_ctrl, reg_dst, alu_src_A, alu_src_B, alu_opp, mem_read_source, mem_write_source, mem_write, wb, mem_to_reg};
    //             end
    //             OPP_XORI : begin
    //                 next_pc_src <= CTRL_NEXT_PC_SRC_SEQ;
    //                 jmp_ctrl <= CTRL_NOT_JMP;
    //                 reg_dst <= CTRL_REG_DST_RT;
    //                 alu_src_A <= ALU_CTRL_SRC_A_BUS_A;
    //                 alu_src_B <= ALU_CTRL_SRC_B_USIG_INM;
    //                 alu_opp <= ALU_CTRL_XORI;
    //                 mem_read_source <= CTRL_MEM_RD_SRC_NOTHING;
    //                 mem_write_source <= CTRL_MEM_WR_SRC_NOTHING;
    //                 mem_write <= CTRL_MEM_WRITE_DISABLE;
    //                 wb <= CTRL_WB_ENABLE;
    //                 mem_to_reg <= CTRL_MEM_TO_REG_ALU_RESULT;
    //                 ctrl_register = {next_pc_src, jmp_ctrl, reg_dst, alu_src_A, alu_src_B, alu_opp, mem_read_source, mem_write_source, mem_write, wb, mem_to_reg};
    //             end
    //             OPP_SLTI : begin
    //                 next_pc_src <= CTRL_NEXT_PC_SRC_SEQ;
    //                 jmp_ctrl <= CTRL_NOT_JMP;
    //                 reg_dst <= CTRL_REG_DST_RT;
    //                 alu_src_A <= ALU_CTRL_SRC_A_BUS_A;
    //                 alu_src_B <= ALU_CTRL_SRC_B_SIG_INM;
    //                 alu_opp <= ALU_CTRL_SLTI;
    //                 mem_read_source <= CTRL_MEM_RD_SRC_NOTHING;
    //                 mem_write_source <= CTRL_MEM_WR_SRC_NOTHING;
    //                 mem_write <= CTRL_MEM_WRITE_DISABLE;
    //                 wb <= CTRL_WB_ENABLE;
    //                 mem_to_reg <= CTRL_MEM_TO_REG_ALU_RESULT;
    //                 ctrl_register = {next_pc_src, jmp_ctrl, reg_dst, alu_src_A, alu_src_B, alu_opp, mem_read_source, mem_write_source, mem_write, wb, mem_to_reg};
    //             end
    //             OPP_LUI : begin
    //                 next_pc_src <= CTRL_NEXT_PC_SRC_SEQ;
    //                 jmp_ctrl <= CTRL_NOT_JMP;
    //                 reg_dst <= CTRL_REG_DST_RT;
    //                 alu_src_A <= ALU_CTRL_SRC_A_BUS_A;
    //                 alu_src_B <= ALU_CTRL_SRC_B_UPPER_INM;
    //                 alu_opp <= ALU_CTRL_LOAD_TYPE;
    //                 mem_read_source <= CTRL_MEM_RD_SRC_NOTHING;
    //                 mem_write_source <= CTRL_MEM_WR_SRC_NOTHING;
    //                 mem_write <= CTRL_MEM_WRITE_DISABLE;
    //                 wb <= CTRL_WB_ENABLE;
    //                 mem_to_reg <= CTRL_MEM_TO_REG_ALU_RESULT;
    //                 ctrl_register = {next_pc_src, jmp_ctrl, reg_dst, alu_src_A, alu_src_B, alu_opp, mem_read_source, mem_write_source, mem_write, wb, mem_to_reg};
    //             end
    //             OPP_LB : begin
    //                 next_pc_src <= CTRL_NEXT_PC_SRC_SEQ;
    //                 jmp_ctrl <= CTRL_NOT_JMP;
    //                 reg_dst <= CTRL_REG_DST_RT;
    //                 alu_src_A <= ALU_CTRL_SRC_A_BUS_A;
    //                 alu_src_B <= ALU_CTRL_SRC_B_SIG_INM;
    //                 alu_opp <= ALU_CTRL_LOAD_TYPE;
    //                 mem_read_source <= CTRL_MEM_RD_SRC_SIG_BYTE;
    //                 mem_write_source <= CTRL_MEM_WR_SRC_NOTHING;
    //                 mem_write <= CTRL_MEM_WRITE_DISABLE;
    //                 wb <= CTRL_WB_ENABLE;
    //                 mem_to_reg <= CTRL_MEM_TO_REG_MEM_RESULT;
    //                 ctrl_register = {next_pc_src, jmp_ctrl, reg_dst, alu_src_A, alu_src_B, alu_opp, mem_read_source, mem_write_source, mem_write, wb, mem_to_reg};
    //             end
    //             OPP_LBU : begin
    //                 next_pc_src <= CTRL_NEXT_PC_SRC_SEQ;
    //                 jmp_ctrl <= CTRL_NOT_JMP;
    //                 reg_dst <= CTRL_REG_DST_RT;
    //                 alu_src_A <= ALU_CTRL_SRC_A_BUS_A;
    //                 alu_src_B <= ALU_CTRL_SRC_B_SIG_INM;
    //                 alu_opp <= ALU_CTRL_LOAD_TYPE;
    //                 mem_read_source <= CTRL_MEM_RD_SRC_USIG_BYTE;
    //                 mem_write_source <= CTRL_MEM_WR_SRC_NOTHING;
    //                 mem_write <= CTRL_MEM_WRITE_DISABLE;
    //                 wb <= CTRL_WB_ENABLE;
    //                 mem_to_reg <= CTRL_MEM_TO_REG_MEM_RESULT;
    //                 ctrl_register = {next_pc_src, jmp_ctrl, reg_dst, alu_src_A, alu_src_B, alu_opp, mem_read_source, mem_write_source, mem_write, wb, mem_to_reg};
    //             end
    //             OPP_LH : begin
    //                 next_pc_src <= CTRL_NEXT_PC_SRC_SEQ;
    //                 jmp_ctrl <= CTRL_NOT_JMP;
    //                 reg_dst <= CTRL_REG_DST_RT;
    //                 alu_src_A <= ALU_CTRL_SRC_A_BUS_A;
    //                 alu_src_B <= ALU_CTRL_SRC_B_SIG_INM;
    //                 alu_opp <= ALU_CTRL_LOAD_TYPE;
    //                 mem_read_source <= CTRL_MEM_RD_SRC_SIG_HALFWORD;
    //                 mem_write_source <= CTRL_MEM_WR_SRC_NOTHING;
    //                 mem_write <= CTRL_MEM_WRITE_DISABLE;
    //                 wb <= CTRL_WB_ENABLE;
    //                 mem_to_reg <= CTRL_MEM_TO_REG_MEM_RESULT;
    //                 ctrl_register = {next_pc_src, jmp_ctrl, reg_dst, alu_src_A, alu_src_B, alu_opp, mem_read_source, mem_write_source, mem_write, wb, mem_to_reg};
    //             end
    //             OPP_LHU : begin
    //                 next_pc_src <= CTRL_NEXT_PC_SRC_SEQ;
    //                 jmp_ctrl <= CTRL_NOT_JMP;
    //                 reg_dst <= CTRL_REG_DST_RT;
    //                 alu_src_A <= ALU_CTRL_SRC_A_BUS_A;
    //                 alu_src_B <= ALU_CTRL_SRC_B_SIG_INM;
    //                 alu_opp <= ALU_CTRL_LOAD_TYPE;
    //                 mem_read_source <= CTRL_MEM_RD_SRC_USIG_HALFWORD;
    //                 mem_write_source <= CTRL_MEM_WR_SRC_NOTHING;
    //                 mem_write <= CTRL_MEM_WRITE_DISABLE;
    //                 wb <= CTRL_WB_ENABLE;
    //                 mem_to_reg <= CTRL_MEM_TO_REG_MEM_RESULT;
    //                 ctrl_register = {next_pc_src, jmp_ctrl, reg_dst, alu_src_A, alu_src_B, alu_opp, mem_read_source, mem_write_source, mem_write, wb, mem_to_reg};
    //             end
    //             OPP_LWU : begin
    //                 next_pc_src <= CTRL_NEXT_PC_SRC_SEQ;
    //                 jmp_ctrl <= CTRL_NOT_JMP;
    //                 reg_dst <= CTRL_REG_DST_RT;
    //                 alu_src_A <= ALU_CTRL_SRC_A_BUS_A;
    //                 alu_src_B <= ALU_CTRL_SRC_B_SIG_INM;
    //                 alu_opp <= ALU_CTRL_LOAD_TYPE;
    //                 mem_read_source <= CTRL_MEM_RD_SRC_USIG_HALFWORD;
    //                 mem_write_source <= CTRL_MEM_WR_SRC_NOTHING;
    //                 mem_write <= CTRL_MEM_WRITE_DISABLE;
    //                 wb <= CTRL_WB_ENABLE;
    //                 mem_to_reg <= CTRL_MEM_TO_REG_MEM_RESULT;
    //                 ctrl_register = {next_pc_src, jmp_ctrl, reg_dst, alu_src_A, alu_src_B, alu_opp, mem_read_source, mem_write_source, mem_write, wb, mem_to_reg};
    //             end
    //             OPP_SB : begin
    //                 next_pc_src <= CTRL_NEXT_PC_SRC_SEQ;
    //                 jmp_ctrl <= CTRL_NOT_JMP;
    //                 reg_dst <= CTRL_REG_DST_NOTHING;
    //                 alu_src_A <= ALU_CTRL_SRC_A_BUS_A;
    //                 alu_src_B <= ALU_CTRL_SRC_B_SIG_INM;
    //                 alu_opp <= ALU_CTRL_STORE_TYPE;
    //                 mem_read_source <= CTRL_MEM_RD_SRC_NOTHING;
    //                 mem_write_source <= CTRL_MEM_WR_SRC_WORD;
    //                 mem_write <= CTRL_MEM_WRITE_ENABLE;
    //                 wb <= CTRL_WB_DISABLE;
    //                 mem_to_reg <= CTRL_MEM_TO_REG_NOTHING;
    //                 ctrl_register = {next_pc_src, jmp_ctrl, reg_dst, alu_src_A, alu_src_B, alu_opp, mem_read_source, mem_write_source, mem_write, wb, mem_to_reg};
    //             end
    //             OPP_SH : begin
    //                 next_pc_src <= CTRL_NEXT_PC_SRC_SEQ;
    //                 jmp_ctrl <= CTRL_NOT_JMP;
    //                 reg_dst <= CTRL_REG_DST_NOTHING;
    //                 alu_src_A <= ALU_CTRL_SRC_A_BUS_A;
    //                 alu_src_B <= ALU_CTRL_SRC_B_SIG_INM;
    //                 alu_opp <= ALU_CTRL_STORE_TYPE;
    //                 mem_read_source <= CTRL_MEM_RD_SRC_NOTHING;
    //                 mem_write_source <= CTRL_MEM_WR_SRC_WORD;
    //                 mem_write <= CTRL_MEM_WRITE_ENABLE;
    //                 wb <= CTRL_WB_DISABLE;
    //                 mem_to_reg <= CTRL_MEM_TO_REG_NOTHING;
    //                 ctrl_register = {next_pc_src, jmp_ctrl, reg_dst, alu_src_A, alu_src_B, alu_opp, mem_read_source, mem_write_source, mem_write, wb, mem_to_reg};
    //             end
    //             default : begin
    //                 next_pc_src <= CTRL_NEXT_PC_SRC_SEQ;
    //                 jmp_ctrl <= CTRL_NOT_JMP;
    //                 reg_dst <= CTRL_REG_DST_RD;
    //                 alu_src_A <= ALU_CTRL_SRC_A_BUS_A;
    //                 alu_src_B <= ALU_CTRL_SRC_B_BUS_B;
    //                 alu_opp <= ALU_CTRL_R_TYPE;
    //                 mem_read_source <= CTRL_MEM_RD_SRC_NOTHING;
    //                 mem_write_source <= CTRL_MEM_WR_SRC_NOTHING;
    //                 mem_write <= CTRL_MEM_WRITE_DISABLE;
    //                 wb <= CTRL_WB_ENABLE;
    //                 mem_to_reg <= CTRL_MEM_TO_REG_ALU_RESULT;
    //                 ctrl_register = {next_pc_src, jmp_ctrl, reg_dst, alu_src_A, alu_src_B, alu_opp, mem_read_source, mem_write_source, mem_write, wb, mem_to_reg};
    //             end
    //         endcase
    //     else
    //         next_pc_src <= CTRL_NEXT_PC_SRC_SEQ;
    //         jmp_ctrl <= CTRL_NOT_JMP;
    //         reg_dst <= CTRL_REG_DST_NOTHING;
    //         alu_src_A <= ALU_CTRL_SRC_A_NOTHING;
    //         alu_src_B <= ALU_CTRL_SRC_B_NOTHING;
    //         alu_opp <= ALU_CTRL_UNDEFINED;
    //         mem_read_source <= CTRL_MEM_RD_SRC_NOTHING;
    //         mem_write_source <= CTRL_MEM_WR_SRC_NOTHING;
    //         mem_write <= CTRL_MEM_WRITE_DISABLE;
    //         wb <= CTRL_WB_DISABLE;
    //         mem_to_reg <= CTRL_MEM_TO_REG_NOTHING;
    //         ctrl_register = {next_pc_src, jmp_ctrl, reg_dst, alu_src_A, alu_src_B, alu_opp, mem_read_source, mem_write_source, mem_write, wb, mem_to_reg};
    // end
        if (!i_instr_nop)
            case (i_opp)
                OPP_LB   : ctrl_register = { CTRL_NEXT_PC_SRC_SEQ,      CTRL_NOT_JMP,    CTRL_REG_DST_RT,      ALU_CTRL_SRC_A_BUS_A,   ALU_CTRL_SRC_B_SIG_INM,     ALU_CTRL_LOAD_TYPE,   CTRL_MEM_RD_SRC_SIG_BYTE,      CTRL_MEM_WR_SRC_NOTHING,  CTRL_MEM_WRITE_DISABLE, CTRL_WB_ENABLE,  CTRL_MEM_TO_REG_MEM_RESULT };
                OPP_LH   : ctrl_register = { CTRL_NEXT_PC_SRC_SEQ,      CTRL_NOT_JMP,    CTRL_REG_DST_RT,      ALU_CTRL_SRC_A_BUS_A,   ALU_CTRL_SRC_B_SIG_INM,     ALU_CTRL_LOAD_TYPE,   CTRL_MEM_RD_SRC_SIG_HALFWORD,  CTRL_MEM_WR_SRC_NOTHING,  CTRL_MEM_WRITE_DISABLE, CTRL_WB_ENABLE,  CTRL_MEM_TO_REG_MEM_RESULT };
                OPP_LW   : ctrl_register = { CTRL_NEXT_PC_SRC_SEQ,      CTRL_NOT_JMP,    CTRL_REG_DST_RT,      ALU_CTRL_SRC_A_BUS_A,   ALU_CTRL_SRC_B_SIG_INM,     ALU_CTRL_LOAD_TYPE,   CTRL_MEM_RD_SRC_WORD,          CTRL_MEM_WR_SRC_NOTHING,  CTRL_MEM_WRITE_DISABLE, CTRL_WB_ENABLE,  CTRL_MEM_TO_REG_MEM_RESULT };
                OPP_LWU  : ctrl_register = { CTRL_NEXT_PC_SRC_SEQ,      CTRL_NOT_JMP,    CTRL_REG_DST_RT,      ALU_CTRL_SRC_A_BUS_A,   ALU_CTRL_SRC_B_SIG_INM,     ALU_CTRL_LOAD_TYPE,   CTRL_MEM_RD_SRC_WORD,          CTRL_MEM_WR_SRC_NOTHING,  CTRL_MEM_WRITE_DISABLE, CTRL_WB_ENABLE,  CTRL_MEM_TO_REG_MEM_RESULT };
                OPP_LBU  : ctrl_register = { CTRL_NEXT_PC_SRC_SEQ,      CTRL_NOT_JMP,    CTRL_REG_DST_RT,      ALU_CTRL_SRC_A_BUS_A,   ALU_CTRL_SRC_B_SIG_INM,     ALU_CTRL_LOAD_TYPE,   CTRL_MEM_RD_SRC_USIG_BYTE,     CTRL_MEM_WR_SRC_NOTHING,  CTRL_MEM_WRITE_DISABLE, CTRL_WB_ENABLE,  CTRL_MEM_TO_REG_MEM_RESULT };
                OPP_LHU  : ctrl_register = { CTRL_NEXT_PC_SRC_SEQ,      CTRL_NOT_JMP,    CTRL_REG_DST_RT,      ALU_CTRL_SRC_A_BUS_A,   ALU_CTRL_SRC_B_SIG_INM,     ALU_CTRL_LOAD_TYPE,   CTRL_MEM_RD_SRC_USIG_HALFWORD, CTRL_MEM_WR_SRC_NOTHING,  CTRL_MEM_WRITE_DISABLE, CTRL_WB_ENABLE,  CTRL_MEM_TO_REG_MEM_RESULT };
                OPP_SB   : ctrl_register = { CTRL_NEXT_PC_SRC_SEQ,      CTRL_NOT_JMP,    CTRL_REG_DST_NOTHING, ALU_CTRL_SRC_A_BUS_A,   ALU_CTRL_SRC_B_SIG_INM,     ALU_CTRL_STORE_TYPE,  CTRL_MEM_RD_SRC_NOTHING,       CTRL_MEM_WR_SRC_BYTE,     CTRL_MEM_WRITE_ENABLE,  CTRL_WB_DISABLE, CTRL_MEM_TO_REG_NOTHING    };
                OPP_SH   : ctrl_register = { CTRL_NEXT_PC_SRC_SEQ,      CTRL_NOT_JMP,    CTRL_REG_DST_NOTHING, ALU_CTRL_SRC_A_BUS_A,   ALU_CTRL_SRC_B_SIG_INM,     ALU_CTRL_STORE_TYPE,  CTRL_MEM_RD_SRC_NOTHING,       CTRL_MEM_WR_SRC_HALFWORD, CTRL_MEM_WRITE_ENABLE,  CTRL_WB_DISABLE, CTRL_MEM_TO_REG_NOTHING    };
                OPP_SW   : ctrl_register = { CTRL_NEXT_PC_SRC_SEQ,      CTRL_NOT_JMP,    CTRL_REG_DST_NOTHING, ALU_CTRL_SRC_A_BUS_A,   ALU_CTRL_SRC_B_SIG_INM,     ALU_CTRL_STORE_TYPE,  CTRL_MEM_RD_SRC_NOTHING,       CTRL_MEM_WR_SRC_WORD,     CTRL_MEM_WRITE_ENABLE,  CTRL_WB_DISABLE, CTRL_MEM_TO_REG_NOTHING    };
                OPP_ADDI : ctrl_register = { CTRL_NEXT_PC_SRC_SEQ,      CTRL_NOT_JMP,    CTRL_REG_DST_RT,      ALU_CTRL_SRC_A_BUS_A,   ALU_CTRL_SRC_B_SIG_INM,     ALU_CTRL_ADDI,        CTRL_MEM_RD_SRC_NOTHING,       CTRL_MEM_WR_SRC_NOTHING,  CTRL_MEM_WRITE_DISABLE, CTRL_WB_ENABLE,  CTRL_MEM_TO_REG_ALU_RESULT };
                OPP_ANDI : ctrl_register = { CTRL_NEXT_PC_SRC_SEQ,      CTRL_NOT_JMP,    CTRL_REG_DST_RT,      ALU_CTRL_SRC_A_BUS_A,   ALU_CTRL_SRC_B_USIG_INM,    ALU_CTRL_ANDI,        CTRL_MEM_RD_SRC_NOTHING,       CTRL_MEM_WR_SRC_NOTHING,  CTRL_MEM_WRITE_DISABLE, CTRL_WB_ENABLE,  CTRL_MEM_TO_REG_ALU_RESULT };
                OPP_ORI  : ctrl_register = { CTRL_NEXT_PC_SRC_SEQ,      CTRL_NOT_JMP,    CTRL_REG_DST_RT,      ALU_CTRL_SRC_A_BUS_A,   ALU_CTRL_SRC_B_USIG_INM,    ALU_CTRL_ORI,         CTRL_MEM_RD_SRC_NOTHING,       CTRL_MEM_WR_SRC_NOTHING,  CTRL_MEM_WRITE_DISABLE, CTRL_WB_ENABLE,  CTRL_MEM_TO_REG_ALU_RESULT };
                OPP_XORI : ctrl_register = { CTRL_NEXT_PC_SRC_SEQ,      CTRL_NOT_JMP,    CTRL_REG_DST_RT,      ALU_CTRL_SRC_A_BUS_A,   ALU_CTRL_SRC_B_USIG_INM,    ALU_CTRL_XORI,        CTRL_MEM_RD_SRC_NOTHING,       CTRL_MEM_WR_SRC_NOTHING,  CTRL_MEM_WRITE_DISABLE, CTRL_WB_ENABLE,  CTRL_MEM_TO_REG_ALU_RESULT };
                OPP_LUI  : ctrl_register = { CTRL_NEXT_PC_SRC_SEQ,      CTRL_NOT_JMP,    CTRL_REG_DST_RT,      ALU_CTRL_SRC_A_BUS_A,   ALU_CTRL_SRC_B_UPPER_INM,   ALU_CTRL_LOAD_TYPE,   CTRL_MEM_RD_SRC_NOTHING,       CTRL_MEM_WR_SRC_NOTHING,  CTRL_MEM_WRITE_DISABLE, CTRL_WB_ENABLE,  CTRL_MEM_TO_REG_ALU_RESULT };
                OPP_SLTI : ctrl_register = { CTRL_NEXT_PC_SRC_SEQ,      CTRL_NOT_JMP,    CTRL_REG_DST_RT,      ALU_CTRL_SRC_A_BUS_A,   ALU_CTRL_SRC_B_SIG_INM,     ALU_CTRL_SLTI,        CTRL_MEM_RD_SRC_NOTHING,       CTRL_MEM_WR_SRC_NOTHING,  CTRL_MEM_WRITE_DISABLE, CTRL_WB_ENABLE,  CTRL_MEM_TO_REG_ALU_RESULT };
                OPP_BEQ  : ctrl_register = { i_are_equal ? { CTRL_NEXT_PC_SRC_NOT_SEQ, CTRL_JMP_BRANCH } : { CTRL_NEXT_PC_SRC_SEQ, CTRL_NOT_JMP }, CTRL_REG_DST_NOTHING, ALU_CTRL_SRC_A_NOTHING, ALU_CTRL_SRC_B_NOTHING,     ALU_CTRL_BRANCH_TYPE, CTRL_MEM_RD_SRC_NOTHING,       CTRL_MEM_WR_SRC_NOTHING,  CTRL_MEM_WRITE_DISABLE, CTRL_WB_DISABLE, CTRL_MEM_TO_REG_NOTHING    };
                OPP_BNE  : ctrl_register = { !i_are_equal ? { CTRL_NEXT_PC_SRC_NOT_SEQ, CTRL_JMP_BRANCH } : { CTRL_NEXT_PC_SRC_SEQ, CTRL_NOT_JMP }, CTRL_REG_DST_NOTHING, ALU_CTRL_SRC_A_NOTHING, ALU_CTRL_SRC_B_NOTHING,     ALU_CTRL_BRANCH_TYPE, CTRL_MEM_RD_SRC_NOTHING,       CTRL_MEM_WR_SRC_NOTHING,  CTRL_MEM_WRITE_DISABLE, CTRL_WB_DISABLE, CTRL_MEM_TO_REG_NOTHING    };
                OPP_J    : ctrl_register = { CTRL_NEXT_PC_SRC_NOT_SEQ,  CTRL_JMP_DIR,    CTRL_REG_DST_NOTHING, ALU_CTRL_SRC_A_NOTHING, ALU_CTRL_SRC_B_NOTHING,     ALU_CTRL_JUMP_TYPE,   CTRL_MEM_RD_SRC_NOTHING,       CTRL_MEM_WR_SRC_NOTHING,  CTRL_MEM_WRITE_DISABLE, CTRL_WB_DISABLE, CTRL_MEM_TO_REG_NOTHING    };
                OPP_JAL  : ctrl_register = { CTRL_NEXT_PC_SRC_NOT_SEQ,  CTRL_JMP_DIR,    CTRL_REG_DST_GPR_31,  ALU_CTRL_SRC_A_NOTHING, ALU_CTRL_SRC_B_NEXT_SEQ_PC, ALU_CTRL_JUMP_TYPE,   CTRL_MEM_RD_SRC_NOTHING,       CTRL_MEM_WR_SRC_NOTHING,  CTRL_MEM_WRITE_DISABLE, CTRL_WB_ENABLE,  CTRL_MEM_TO_REG_ALU_RESULT };
                OPP_R_TYPE :
                    case (i_funct)
                        FUNCT_SLL   : ctrl_register = { CTRL_NEXT_PC_SRC_SEQ,     CTRL_NOT_JMP, CTRL_REG_DST_RD,      ALU_CTRL_SRC_A_SHAMT,   ALU_CTRL_SRC_B_BUS_B,       ALU_CTRL_R_TYPE, CTRL_MEM_RD_SRC_NOTHING, CTRL_MEM_WR_SRC_NOTHING, CTRL_MEM_WRITE_DISABLE, CTRL_WB_ENABLE,  CTRL_MEM_TO_REG_ALU_RESULT };
                        FUNCT_SRL   : ctrl_register = { CTRL_NEXT_PC_SRC_SEQ,     CTRL_NOT_JMP, CTRL_REG_DST_RD,      ALU_CTRL_SRC_A_SHAMT,   ALU_CTRL_SRC_B_BUS_B,       ALU_CTRL_R_TYPE, CTRL_MEM_RD_SRC_NOTHING, CTRL_MEM_WR_SRC_NOTHING, CTRL_MEM_WRITE_DISABLE, CTRL_WB_ENABLE,  CTRL_MEM_TO_REG_ALU_RESULT };
                        FUNCT_SRA   : ctrl_register = { CTRL_NEXT_PC_SRC_SEQ,     CTRL_NOT_JMP, CTRL_REG_DST_RD,      ALU_CTRL_SRC_A_SHAMT,   ALU_CTRL_SRC_B_BUS_B,       ALU_CTRL_R_TYPE, CTRL_MEM_RD_SRC_NOTHING, CTRL_MEM_WR_SRC_NOTHING, CTRL_MEM_WRITE_DISABLE, CTRL_WB_ENABLE,  CTRL_MEM_TO_REG_ALU_RESULT };
                        FUNCT_JR    : ctrl_register = { CTRL_NEXT_PC_SRC_NOT_SEQ, CTRL_JMP_REG, CTRL_REG_DST_NOTHING, ALU_CTRL_SRC_A_NOTHING, ALU_CTRL_SRC_B_NOTHING,     ALU_CTRL_R_TYPE, CTRL_MEM_RD_SRC_NOTHING, CTRL_MEM_WR_SRC_NOTHING, CTRL_MEM_WRITE_DISABLE, CTRL_WB_DISABLE, CTRL_MEM_TO_REG_NOTHING    };
                        FUNCT_JALR  : ctrl_register = { CTRL_NEXT_PC_SRC_NOT_SEQ, CTRL_JMP_REG, CTRL_REG_DST_GPR_31,  ALU_CTRL_SRC_A_BUS_A,   ALU_CTRL_SRC_B_NEXT_SEQ_PC, ALU_CTRL_R_TYPE, CTRL_MEM_RD_SRC_NOTHING, CTRL_MEM_WR_SRC_NOTHING, CTRL_MEM_WRITE_DISABLE, CTRL_WB_ENABLE,  CTRL_MEM_TO_REG_ALU_RESULT };
                        default     : ctrl_register = { CTRL_NEXT_PC_SRC_SEQ,    CTRL_NOT_JMP, CTRL_REG_DST_RD,      ALU_CTRL_SRC_A_BUS_A,   ALU_CTRL_SRC_B_BUS_B,       ALU_CTRL_R_TYPE, CTRL_MEM_RD_SRC_NOTHING, CTRL_MEM_WR_SRC_NOTHING, CTRL_MEM_WRITE_DISABLE, CTRL_WB_ENABLE,  CTRL_MEM_TO_REG_ALU_RESULT };
                    endcase
                default       : ctrl_register = { CTRL_NEXT_PC_SRC_SEQ,      CTRL_NOT_JMP,    CTRL_REG_DST_NOTHING, ALU_CTRL_SRC_A_NOTHING, ALU_CTRL_SRC_B_NOTHING,     ALU_CTRL_UNDEFINED ,  CTRL_MEM_RD_SRC_NOTHING,       CTRL_MEM_WR_SRC_NOTHING,  CTRL_MEM_WRITE_DISABLE, CTRL_WB_DISABLE, CTRL_MEM_TO_REG_NOTHING    };
            endcase
        else
            ctrl_register = { CTRL_NEXT_PC_SRC_SEQ, CTRL_NOT_JMP, CTRL_REG_DST_NOTHING, ALU_CTRL_SRC_A_NOTHING, ALU_CTRL_SRC_B_NOTHING, ALU_CTRL_UNDEFINED, CTRL_MEM_RD_SRC_NOTHING, CTRL_MEM_WR_SRC_NOTHING, CTRL_MEM_WRITE_DISABLE, CTRL_WB_DISABLE, CTRL_MEM_TO_REG_NOTHING };
        end

    assign o_ctrl_register = ctrl_register;
    //assign o_ctrl_register = {next_pc_src, jmp_ctrl, reg_dst, alu_src_A, alu_src_B, alu_opp, mem_read_source, mem_write_source, mem_write, wb, mem_to_reg};

endmodule