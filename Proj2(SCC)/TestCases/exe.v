// EXE handles all ALU operations and LD/STR offsets
module exe(
    input [2:0] alu_Instruct,       // Value here says what ALU we doin
    input [3:0] b_cond,             // Value here says what branch we doin
    input [31:0] op1_reg,           // Reg1 Data
    input [31:0] op2_reg,           // Reg2 Data
    input [15:0] immediate,         // immediate or offset
    input flagFlag,                 // 1 = Set Flags
    input shift_Flag,               // 1 = Logical Shift Occuring
    input immediate_Flag,           // 1 = Swap Op2 for Imm
    input alu_Flag,                 // 1 = ALU operation
    input load_Flag,                // 1 = LD Occuring
    input store_Flag,               // 1 = STR Occuring
    input branch_Flag,              // 1 = we branching
    output reg [31:0] flag_Extended,// Extended Flag reg for MOVF
    output [31:0] result,           // ALU result or memory address
    output reg branchTaken,         // 1 = We taken the branch
    input [31:0] rom_data_1,        // ReadData1 From uCROM
    input [31:0] rom_data_2,        // ReadData2 From uCROM
    input romRegRead_flag,           // 1 = We readin from ROM
    input [31:0] flagWrite,
    input sav_flag,
    input branch_reg
);
    //Branch Conditional codes
    localparam EQ = 0;
    localparam NE = 1;
    localparam CS = 2;
    localparam CC = 3;
    localparam MI = 4;
    localparam PL = 5;
    localparam VS = 6;
    localparam VC = 7;
    localparam HI = 8;
    localparam LS = 9;
    localparam GE = 10;
    localparam LT = 11;
    localparam GT = 12;
    localparam LE = 13;
    localparam AL = 14;
    localparam NV = 15;

    // Sign extend immediate to 32-bits
    wire [31:0] immediate_extended;
    wire [31:0] aluResult;
    reg  [31:0] shiftResult;

    assign result= shift_Flag ? shiftResult : aluResult; //Switch result output between ALU and LSL/R
    assign immediate_extended = {{16{immediate[15]}}, immediate};

    wire [3:0] flags = {negative, zero, carry, overflow};

    // Switch between immediate and reg for operand2 in ALU
    reg [31:0] operand2;
    reg [31:0] operand1;
    always @(*) begin


        if(romRegRead_flag) begin //Switch alu operand to ROM read
                operand1 <= rom_data_1;
            end
            else begin
                if(branch_reg) operand1 <= flagWrite;
                else 
                operand1 <= op1_reg;
            end


        if(immediate_Flag) begin
            operand2 <= immediate_extended;
        end

        else begin
            if(romRegRead_flag) begin //Switch alu operand2 to ROM read
                operand2 <= rom_data_2;
            end
            else begin
                operand2 <= op2_reg;
            end
        end
    end
    // Tells ALU if LD/STR occurs
    wire mem_operation;
    assign mem_operation = load_Flag | store_Flag ; // WTF IS THIS | (branch_Flag & (b_cond == 2));

    //ALU
    alu alu_epic(
        .operand1(operand1),
        .operand2(operand2),
        .alu_Instruction(mem_operation ? 3'b001 : alu_Instruct), // Sets ALU to ADD for mem offset
        .flagFlag(flagFlag),
        .aluFlag(alu_Flag),
        .result(aluResult),
        .zero(zero),
        .overflow(overflow),
        .carry(carry),
        .negative(negative),
        .flagWrite(flagWrite),
        .sav_flag(sav_flag)
    );

    always @(*) begin
        flag_Extended = {28'b0,flags}; //Extended flags reg for MOVF

        case(b_cond) // Sets branchTaken 'flag' depending on which branch conditional
            EQ: branchTaken = zero;
            NE: branchTaken = ~zero;
            CS: branchTaken = carry;
            CC: branchTaken = ~carry;
            MI: branchTaken = negative;
            PL: branchTaken = ~negative;
            VS: branchTaken = overflow;
            VC: branchTaken = ~overflow;
            HI: branchTaken = carry & ~zero;
            LS: branchTaken = ~carry | zero;
            GE: branchTaken = (negative == overflow);
            LT: branchTaken = (negative != overflow);
            GT: branchTaken = ~zero & (negative == overflow);
            LE: branchTaken = ~(~zero & (negative == overflow));
            AL: branchTaken = 1;
            NV: branchTaken = 0;
            default: branchTaken = 0;
        endcase

        if(shift_Flag) begin // Implements LSL and LSR
            case(alu_Instruct)
                4: begin
                    shiftResult <= operand1 << operand2; //LSL
                end

                5: begin
                    shiftResult <= operand1 >> operand2; //LSR
                end

                default: begin
                    shiftResult <= 0;
                end
            endcase
        end
    end

endmodule
