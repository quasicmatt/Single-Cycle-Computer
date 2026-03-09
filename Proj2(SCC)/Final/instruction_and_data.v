//Changes made:
//Changes the output for instruction and data memory values to change when the input pointers change isntead of on clock to make it asynchronous
//Added writing the values of data memory into a output file after a halt flag is high

module instruction_and_data(
  input mem_Clk,
  input instruction_memory_en,
  input [31:0] instruction_memory_a,
  input [31:0] data_memory_a,
  input data_memory_read,
  input data_memory_write,
  input [31:0] data_memory_out_v,
  output reg [31:0] instruction_memory_v,
  output reg [31:0] data_memory_in_v,
  input halt_f
  
);

initial begin
  wait(halt_f); //Waits until the halt instruction is reached before writing what is in data memory to an output file
      file=$fopen("scc_out.txt","w"); //Opening the output file location
      $fwrite(file,"Address,Value\n"); //Write the labels at the top of the file
      $fclose(file); //Closes the file for "w" or write
      for(j=0;j<170;j=j+1) begin //Loops through for each row of the data memory
        file=$fopen("scc_out.txt","a"); //Opening the output file location for "a" or append
        for(i=0;i<392;i=i+4)begin
          location=j*384+i;
          $fwrite(file, "0x%h,0x%h%h%h%h\n",location,memory[j*384+i],memory[j*384+i+1],memory[j*384+i+2],memory[j*384+i+3]); //Appending what is saved at each memory location
        end
        $fclose(file); //Closes the file for append
      end
      
end

reg [7:0] memory [0:(2**16)-1] ; //Maximum array to hold both instruction and data memory

integer file,i,j,file2; //Variables for writing output data
reg [31:0] location; //Address for writing output data

//Always is used for when the pointer for the instruction and data memory location changes instead of on a clock to make it asynchronous
always @(instruction_memory_a) begin
  instruction_memory_v[31:24] <= memory[instruction_memory_a]; //async reads for both instruction and data mem
  instruction_memory_v[23:16] <= memory[instruction_memory_a+1];
  instruction_memory_v[15:8] <= memory[instruction_memory_a+2];
  instruction_memory_v[7:0] <= memory[instruction_memory_a+3];
end
always @(data_memory_a) begin
  data_memory_in_v[31:24] <= memory[data_memory_a];
  data_memory_in_v[23:16] <= memory[data_memory_a+1];
  data_memory_in_v[15:8] <= memory[data_memory_a+2];
  data_memory_in_v[7:0] <= memory[data_memory_a+3];
end

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
  end
  if(data_memory_read) begin //Load instruction
    data_memory_in_v[31:24] <=memory[data_memory_a];
    data_memory_in_v[23:16] <=memory[data_memory_a+1];
    data_memory_in_v[15:8] <=memory[data_memory_a+2];
    data_memory_in_v[7:0] <=memory[data_memory_a+3];
  end*/ //Removed to make intruction and data memory reads asynchronous instead of on clock
  if(data_memory_write) begin //Store instruction
    memory[data_memory_a] <= data_memory_out_v[31:24];
    memory[data_memory_a+1] <= data_memory_out_v[23:16];
    memory[data_memory_a+2] <= data_memory_out_v[15:8];
    memory[data_memory_a+3] <= data_memory_out_v[7:0];
    //data_memory_in_v <= 'bx; //removed because data_memory_in_v is no longer a reg
  end
  
end
endmodule
