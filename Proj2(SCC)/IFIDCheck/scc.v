module scc(
    input clk,
    input rst,
    input halt_f,
    input data_memory_read,
    output data_memory_write,
    input [31:0] instruction_memory_v,
    input [31:0] data_memory_in_v,
    output [31:0] data_memory_a,
    output memReadEn,
    output [31:0] programCounter
);

wire [0:31] instruction;
wire [3:0] b_cond;
wire [3:0] destination_reg;
wire [3:0] op1_reg;
wire [3:0] op2_reg;
wire [15:0] immediate;
wire alu_Flag;
wire flag_Flag;   //flag to say if we are setting flags
wire immediate_Flag; //flag to say if we are using an immediate
wire load_Flag;  //flag for if storing from alu or mem
wire store_Flag;  //flag for if writing to reg or mem
wire branch_Flag; //flag for if branching
wire write_to_reg_Flag; //flag for writing to a reg 
wire [2:0] alu_Instruct;  //flag for what alu instruction
wire [31:0] read_data_1; //output from the corresponding register
wire [31:0] read_data_2;
wire [31:0] write_data; //data to write into a register

//REGS
regs registers(
    .clk(clk),
    .rst(rst),
    .write_to_reg_Flag(write_to_reg_Flag),
    .write_reg(destination_reg),
    .read_reg_1(op1_reg),
    .read_reg_2(op2_reg),
    .write_data(write_data),
    .read_data_1(read_data_1),
    .read_data_2(read_data_2)
);

//IF
inf instruction_fetch(
    clk,
    rst,
    instruction_memory_v,
    instruction,
    programCounter, 
    memReadEn
);

//ID
id the_decoder_forsaken_by_god(
    instruction,
    b_cond,
    destination_reg,
    op1_reg,
    op2_reg,
    immediate,
    alu_Flag,
    flag_Flag,   
    immediate_Flag, 
    load_Flag,  
    store_Flag,
    branch_Flag, 
    write_to_reg_Flag, 
    alu_Instruct  
);
//EXE

//WB


endmodule
