module inf(
    input clk,
    input rst,
    input [31:0] instruction_mem, //From memory
    input [31:0] rom_instruction, //From ROM
    input write_to_reg_Flag, //Writing to 15th register (PC)
    input [3:0] write_reg,
    input [31:0] write_data,
    input [31:0] romWrite_data,
    input branchFlag, //conditional branch flag
    input [31:0] op1_data,
    input [31:0] op2_data,
    output reg [31:0] instruction, //Go to ID
    output reg [31:0] programCounter, //Go to memory
    output [15:0] rom_programCounter, //Go to rom
    output reg memReadEn,
    output [31:0] data_out1,
    output [31:0] data_out2,
    input  [3:0] op1Reg_sel,
    input  [3:0] op2Reg_sel,
    output romRegWrite_flag,
    output romRegRead_flag,
    input [3:0] flags,
    input setCatch,
    input [1:0] mov_flag 
);

reg [1:0] branchOp;
reg [3:0] branchDefine;
reg [31:0] branchImmediate;
reg branchTaken;
reg [31:0] lastInstruction;
wire [31:0] instruction_rom;
wire [31:0] splice_instruction;

always @(*) begin
    if(setCatch==0) begin
        branchOp = instruction_mem[31:30];
        branchDefine = instruction_mem[28:25];
        branchImmediate = {{16{instruction_mem[15]}}, instruction_mem[15:0]};
        if (branchOp == 3 && (branchDefine == 0 )) begin //take branch for unconditional
                programCounter = programCounter + branchImmediate;
        end
        else begin
                programCounter = programCounter;
        end
    end
end

always @(posedge clk) begin
    memReadEn = 1;
    if (rst == 0) begin
        if(setCatch==0) begin
            if (write_to_reg_Flag == 1 && write_reg == 15) begin
                programCounter = write_data;
            end
            else if (branchOp == 3 && (branchDefine == 0 || (branchFlag == 1 && branchDefine == 1))) begin //take branch for conditional
                programCounter = programCounter + branchImmediate;
            end
            else begin
                programCounter = programCounter + 4; //regular program counter increment
            end
        end
    end
    else begin
        programCounter = 0;
        //instruction = 'hC8000000;
    end
end

always @(*) begin
    if(setCatch) begin
        instruction = splice_instruction;
    end
    else begin
        instruction = instruction_mem;
    end
end


test_uC what(
    .clk(clk),
    .rst(rst),
    .orig_instruction(instruction_mem),
    .reg_data1(op1_data),
    .reg_data2(op2_data),
    .data_in(romWrite_data),
    .mov_flag(mov_flag),
    .destReg_sel(write_reg[2:0]),
    .op1Reg_sel(op1Reg_sel[2:0]),
    .op2Reg_sel(op2Reg_sel[2:0]),
    .branchFlag(branchFlag),
    .write_to_reg_Flag(write_to_reg_Flag),
    .setCatch(setCatch),
    .rom_instruction(rom_instruction),
    .instruction(splice_instruction),
    .rom_programCounter(rom_programCounter),
    .romRegWrite_flag(romRegWrite_flag),
    .romRegRead_flag(romRegRead_flag),
    .data_out1(data_out1),
    .data_out2(data_out2)
);

endmodule
