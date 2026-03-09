// EXE handles all ALU operations and LD/STR offsets
module exe(
    input [2:0] alu_Instruct,
    input [3:0] b_cond,
    input [31:0] op1_reg,         // Reg1 Data
    input [31:0] op2_reg,         // Reg2 Data
    input [15:0] immediate,       // immediate or offset
    input flagFlag,
    input immediate_Flag,
    input alu_Flag,
    input load_Flag,
    input store_Flag,
    output reg [31:0] flag_extended,
    output [31:0] result,         // ALU result or memory address
    output reg branchTaken
);
    //Branch Conditional codes
    localparam EQ = 4'b0000;
    localparam NE = 4'b0001;
    localparam CS = 4'b0010;
    localparam CC = 4'b0011;
    localparam MI = 4'b0100;
    localparam PL = 4'b0101;
    localparam VS = 4'b0110;
    localparam VC = 4'b0111;
    localparam HI = 4'b1000;
    localparam LS = 4'b1001;
    localparam GE = 4'b1010;
    localparam LT = 4'b1011;
    localparam GT = 4'b1100;
    localparam LE = 4'b1101;
    localparam AL = 4'b1110;
    localparam NV = 4'b1111;

    // Sign extend immediate to 32-bits
    wire [31:0] immediate_extended;
    assign immediate_extended = {{16{immediate[15]}}, immediate};

    wire [3:0] flags = {negative, zero, carry, overflow};

    // Switch between immediate and reg for operand2 in ALU
    reg [31:0] operand2;
    always @(*) begin
        if(immediate_Flag) begin
            operand2 <= immediate_extended;
        end
        else begin
            operand2 <= op2_reg;
        end
    end
    // Tells ALU if LD/STR occurs
    wire mem_operation;
    assign mem_operation = load_Flag | store_Flag;

    //ALU
    alu alu_epic(
        .operand1(op1_reg),
        .operand2(operand2),
        .alu_Instruction(mem_operation ? 3'b001 : alu_Instruct), // Sets ALU to ADD for mem offset
        .flagFlag(flagFlag),
        .result(result),
        .zero(zero),
        .overflow(overflow),
        .carry(carry),
        .negative(negative)
    );

    always @(*) begin
        flag_extended = {flags, 28'b0};
        case(b_cond)
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
            AL: branchTaken = 1'b1;
            NV: branchTaken = 1'b0;
            default: branchTaken = 1'b0;
        endcase
    end

endmodule
