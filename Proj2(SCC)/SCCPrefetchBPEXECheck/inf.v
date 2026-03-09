module inf(
    input clk,
    input rst,
    input [31:0] instruction_mem, //From memory
    input write_to_reg_Flag, //Writing to 15th register (PC)
    input [3:0] write_reg,
    input [31:0] write_data,
    input branchFlag, //conditional branch flag
    output reg [31:0] instruction, //Go to ID
    output reg [31:0] programCounter, //Go to memory
    output reg memReadEn
);

reg [1:0] branchOp;
reg [3:0] branchDefine;
reg [31:0] branchImmediate;

always @(posedge clk) begin
    memReadEn = 1;
    if (rst == 0) begin
        branchOp = instruction_mem[31:30];
        branchDefine = instruction_mem[28:25];
        branchImmediate = {{16{instruction_mem[15]}}, instruction_mem[15:0]};
        if (write_to_reg_Flag == 1 && write_reg == 15) begin
            programCounter = write_data;
        end
        else if (branchOp == 3 && (branchDefine == 0 || (branchFlag == 1 && branchDefine == 1))) begin //take branch for unconditional
            programCounter = programCounter + branchImmediate;
        end
        else begin
            programCounter = programCounter + 4;
        end
    end
    else begin
        programCounter = 0;
        //instruction = 'hC8000000;
    end
end

always @(programCounter) begin
    instruction = instruction_mem;
end

endmodule
