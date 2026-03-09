module instruction_and_data
(
  input mem_Clk,
  input instruction_memory_en,
  input [31:0] instruction_memory_a,
  input [31:0] data_memory_a,
  input data_memory_read,
  input data_memory_write,
  input [31:0] data_memory_out_v,
  output [31:0] instruction_memory_v,
  output [31:0] data_memory_in_v
);
reg [7:0] memory [0:(2**16)-1] ; //Maximum array to hold both instruction and data memory

assign instruction_memory_v[31:24] = memory[instruction_memory_a]; //async reads for both instruction and data mem
assign instruction_memory_v[23:16] = memory[instruction_memory_a+1];
assign instruction_memory_v[15:8] = memory[instruction_memory_a+2];
assign instruction_memory_v[7:0] = memory[instruction_memory_a+3];

assign data_memory_in_v[31:24] = memory[data_memory_a];
assign data_memory_in_v[23:16] = memory[data_memory_a+1];
assign data_memory_in_v[15:8] = memory[data_memory_a+2];
assign data_memory_in_v[7:0] = memory[data_memory_a+3];

initial begin
  $readmemh("output.mem", memory);
  end
always @(mem_Clk) begin
  /*if(instruction_memory_en)begin //Grabs 32 bit instruction
  instruction_memory_v[31:24] <= memory[instruction_memory_a];
  instruction_memory_v[23:16] <= memory[instruction_memory_a+1];
  instruction_memory_v[15:8] <= memory[instruction_memory_a+2];
  instruction_memory_v[7:0] <= memory[instruction_memory_a+3];
  end
  else if (~instruction_memory_en) begin //When low the SCC program pauses until set back to high which continues fetching instructions
  instruction_memory_v <= 'hFFFFFFFF;
  end*/
  /*if(data_memory_read) begin //Load instruction
    data_memory_in_v[31:24] <=memory[data_memory_a];
    data_memory_in_v[23:16] <=memory[data_memory_a+1];
    data_memory_in_v[15:8] <=memory[data_memory_a+2];
    data_memory_in_v[7:0] <=memory[data_memory_a+3];
  end*/
  if(data_memory_write) begin //Store instruction
    memory[data_memory_a] <= data_memory_out_v[31:24];
    memory[data_memory_a+1] <= data_memory_out_v[23:16];
    memory[data_memory_a+2] <= data_memory_out_v[15:8];
    memory[data_memory_a+3] <= data_memory_out_v[7:0];
    //data_memory_in_v <= 'bx; //removed because data_memory_in_v is no longer a reg
  end
  $writememh("memory_dump.mem", memory );
end
endmodule
