module scc(
    input clk,
    input rst,
    output halt_f,
    output data_memory_read,
    output data_memory_write,
    input [31:0] instruction_memory_v,
    input [31:0] data_memory_in_v,
    output [31:0] data_memory_out_v,
    output [31:0] data_memory_a,
    output memReadEn,
    output [31:0] programCounter
);

wire [31:0] instruction;
wire [3:0] b_cond;
wire [3:0] destination_reg;
wire [3:0] op1_reg;
wire [3:0] op2_reg;
wire [15:0] immediate;
wire [31:0] alu_Result; //EXE ALU Output or mem address
wire alu_Flag;
wire flag_Flag;   //flag to say if we are setting flags
wire immediate_Flag; //flag to say if we are using an immediate
wire load_Flag;  //flag for if storing from alu or mem
wire store_Flag;  //flag for if writing to reg or mem
wire branch_Flag; //flag for if branching
wire branch_Taken; //flag for taking conditional branch
wire write_to_reg_Flag; //flag for writing to a reg 
wire [2:0] alu_Instruct;  //flag for what alu instruction
wire [31:0] read_data_1; //output from the corresponding register
wire [31:0] read_data_2;
wire [31:0] write_data; //data to write into a register
wire [1:0] mov_flag;
wire romReadEn; //enable read to rom for uCODE
wire [31:0] uCodeProgramCounter;
wire [31:0] uCodeInstructionMemory;

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
    .read_data_2(read_data_2),
    .store_data(data_memory_out_v)
);

//IF
inf instruction_fetch(
    .clk(clk),
    .rst(rst),
    .instruction_mem(instruction_memory_v),
    .write_to_reg_Flag(write_to_reg_Flag),
    .write_reg(destination_reg),
    .write_data(write_data),
    .branchFlag(branch_Taken),
    .instruction(instruction),
    .programCounter(programCounter),
    .memReadEn(memReadEn)
);

//ID
id the_decoder_forsaken_by_god(
    instruction,
    halt_f,
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
    alu_Instruct,
    mov_flag  
);
//EXE
exe Execute(
    .alu_Instruct(alu_Instruct),
    .b_cond(b_cond),
    .op1_reg(read_data_1), //not great naming mb -NL (gonna change later but lowkey didn't know what op1_reg was doing when I wrote the inputs)
    .op2_reg(read_data_2),
    .immediate(immediate),
    .flagFlag(flag_Flag),
    .immediate_Flag(immediate_Flag),
    .alu_Flag(alu_Flag),
    .load_Flag(load_Flag),
    .store_Flag(store_Flag),
    .result(alu_Result),
    .branchTaken(branch_Taken)
);
//WB
mem memoryPlease(
    .load_Flag(load_Flag),
    .store_Flag(store_Flag),
    .alu_Result(alu_Result),
    .mem_destination(data_memory_a),
    .memRead(data_memory_read),
    .memWrite(data_memory_write)
);

wb writeBack(
    .mem_data(data_memory_in_v),
    .alu_Result(alu_Result),
    .load_Flag(load_Flag),
    .immediate_Flag(immediate_Flag),
    .mov_Flag(mov_flag),
    .reg_in(read_data_1),
    .imm_in(immediate),
    .output_Data(write_data)
);
//uCODE

instruction_rom rom(
    .mem_Clk(clk),
    .instruction_memory_en(romReadEn),
    .instruction_memory_a(uCodeProgramCounter),
    .instruction_memory_v(uCodeProgramCounter)
);

endmodule
