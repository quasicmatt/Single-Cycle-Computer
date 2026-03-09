module rom(
    input clk,
    input rst,
    input  [31:0] original_instruct,
    output [31:0] instruction,
    output [31:0] data_out1,
    output [31:0] data_out2,
    input  [31:0] data_in,
    input  [2:0] destReg_sel,
    input  [2:0] op1Reg_sel,
    input  [2:0] op2Reg_sel,
    output romRegWrite_flag,
    output romRegRead_flag
    input carry_flag
) 

reg [31:0] romReg[0:3];
reg [15:0] programCounter;
reg negFlag;
reg internalCarry;
reg internalOverflow;
reg internalZero;
reg internalNeg;

//New variables IF
reg [1:0] branchOpRom;
reg [3:0] branchDefineRom;
reg [31:0] branchImmediateRom;

//REGS
reg [31:0] data_out1, data_out2;

//IF
always @(*) begin
    branchOpRom = instruction[31:30];
    branchDefineRom = instruction[28:25];
    branchImmediateRom = {{16{instruction[15]}}, instruction[15:0]};
    if (branchOpRom == 3 && (branchDefineRom == 0 )) begin //take branch for unconditional
            programCounter = programCounter + branchImmediateRom;
    end
    else begin
            programCounter = programCounter;
    end
end

always @(posedge clk) begin
    if (rst == 0) begin
        if (branchOpRom == 3 && branchFlag == 1 && branchDefineRom == 1) begin //take branch for conditional
            programCounter = programCounter + branchImmediateRom;
        end
        else begin
            programCounter = programCounter + 4;
        end
    end
    else begin
        programCounter = 0;
    end
end

//REGS
always @(*) begin
    data_out1 = regs[op1Reg_sel]; //reading the associated register number
    data_out2 = regs[op2Reg_sel];
end

always@(posedge clk) begin
    if (rst == 0) begin
        if (romRegWrite_flag == 1) begin
            romReg[destReg_sel] = data_in; //if write_Flag is enabled, write the input data to the chosen register
        end
        else begin
            romReg[destReg_sel] = romReg[destReg_sel]; //if write_Flag is disabled, the chosen register saves its current value
        end
    end
    else begin
        {romReg[0], romReg[1], romReg[2], romReg[3]} = 0; //sets all regs to 0
    end
end
endmodule
