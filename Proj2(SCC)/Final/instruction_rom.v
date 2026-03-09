//This is a cutdown version of the original memory module, but only for reading instruction data

module instruction_rom(
  input mem_Clk,
  input instruction_memory_en,
  input [15:0] instruction_memory_a,
  output [31:0] instruction_memory_v
);
reg [7:0] memory [0:(2**16)-1] ; //Maximum array to hold both instruction and data memory

assign instruction_memory_v[31:24] = memory[instruction_memory_a]; //async reads for instruction_rom memory
assign instruction_memory_v[23:16] = memory[instruction_memory_a+1];
assign instruction_memory_v[15:8] = memory[instruction_memory_a+2];
assign instruction_memory_v[7:0] = memory[instruction_memory_a+3];

initial begin
  $readmemh("rom_output.mem", memory);
end

endmodule
