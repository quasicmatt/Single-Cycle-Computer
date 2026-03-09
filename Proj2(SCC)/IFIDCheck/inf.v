module inf(
    input clk,
    input rst,
    input [31:0] instruction_mem, //From memory
    output reg [31:0] instruction, //Go to ID
    output reg [31:0] programCounter, //Go to memory
    output reg memReadEn
);

always@(posedge clk) begin
    memReadEn = 1;
    if (rst == 0) begin
        programCounter = programCounter+4;
        instruction=instruction_mem;
    end
    else begin
        programCounter = 0;
        instruction= 'hC8000000;
    end
end
endmodule