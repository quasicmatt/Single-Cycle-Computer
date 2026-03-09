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
wire romRegWrite_flag;
wire [2:0] alu_Instruct;  //flag for what alu instruction
wire [31:0] read_data_1; //output from the corresponding register
wire [31:0] read_data_2;
wire [31:0] rom_data_1; //output from the corresponding register
wire [31:0] rom_data_2;
wire [31:0] write_data; //data to write into a register
wire [31:0] romWrite_data;
wire [31:0] rom_instruction;
wire [15:0] rom_programCounter;
wire [1:0] mov_flag;
wire romRegRead_flag;
wire [31:0] flag_Extended;
wire shift_Flag;
wire setCatch;
wire sav_flag;
wire branch_reg;
wire preventCatch;

//REGS
regs registers(
    .clk(clk),
    .rst(rst),
    .write_to_reg_Flag(write_to_reg_Flag),
    .write_reg(destination_reg),
    .read_reg_1(op1_reg),
    .read_reg_2(op2_reg),
    .write_data(write_data),
    .mov_Flag(mov_flag),
    .read_data_1(read_data_1),
    .read_data_2(read_data_2),
    .store_data(data_memory_out_v),
    .romRegWriteFlag(romRegWrite_flag)
);

//IF
inf instruction_fetch(
    .clk(clk),
    .rst(rst),
    .instruction_mem(instruction_memory_v),
    .rom_instruction(rom_instruction),
    .write_to_reg_Flag(write_to_reg_Flag),
    .write_reg(destination_reg),
    .write_data(write_data),
    .romWrite_data(romWrite_data),
    .branchFlag(branch_Taken),
    .instruction(instruction),
    .programCounter(programCounter),
    .rom_programCounter(rom_programCounter),
    .memReadEn(memReadEn),
    .data_out1(rom_data_1),
    .data_out2(rom_data_2),
    .op1Reg_sel(op1_reg),
    .op2Reg_sel(op2_reg),
    .romRegWrite_flag(romRegWrite_flag),
    .romRegRead_flag(romRegRead_flag),
    .flags(flag_Extended[3:0]),
    .setCatch(setCatch),
    .mov_flag(mov_flag),
    .branch_reg(branch_reg),
    .preventCatch(preventCatch),
    .halt_f(halt_f) 
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
    shift_Flag,   
    immediate_Flag, 
    load_Flag,  
    store_Flag,
    branch_Flag, 
    write_to_reg_Flag, 
    alu_Instruct,
    mov_flag,
    clear_flag,
    set_flag,
    setCatch,
    sav_flag,
    branch_reg,
    preventCatch
);
//EXE
exe Execute(
    .alu_Instruct(alu_Instruct),
    .b_cond(b_cond),
    .op1_reg(read_data_1), //not great naming mb -NL (gonna change later but lowkey didn't know what op1_reg was doing when I wrote the inputs)
    .op2_reg(read_data_2),
    .immediate(immediate),
    .flagFlag(flag_Flag),
    .shift_Flag(shift_Flag),
    .immediate_Flag(immediate_Flag),
    .alu_Flag(alu_Flag),
    .load_Flag(load_Flag),
    .store_Flag(store_Flag),
    .branch_Flag(branch_Flag),
    .flag_Extended(flag_Extended),
    .result(alu_Result),
    .branchTaken(branch_Taken),
    .rom_data_1(rom_data_1),
    .rom_data_2(rom_data_2),
    .romRegRead_flag(romRegRead_flag),
    .flagWrite(data_memory_out_v),
    .sav_flag(sav_flag),
    .branch_reg(branch_reg)
);

//WB
mem memoryPlease(
    .load_Flag(load_Flag),
    .store_Flag(store_Flag),
    .alu_Result(alu_Result),
    .mem_destination(data_memory_a),
    .memRead(data_memory_read),
    .data_memory_write(data_memory_write)
);

wb writeBack(
    .data_memory_in_v(data_memory_in_v),
    .alu_Result(alu_Result),
    .load_Flag(load_Flag),
    .clear_flag(clear_flag),
    .set_flag(set_flag),
    .immediate_Flag(immediate_Flag),
    .romRegWrite_flag(romRegWrite_flag),
    .mov_Flag(mov_flag),
    .reg_in(read_data_1),
    .imm_in(immediate),
    .flag_Extended(flag_Extended),
    .output_Data(write_data),
    .romoutput_Data(romWrite_data)
);

//ROM
instruction_rom rom(
    .mem_Clk(clk),
    .instruction_memory_en(memReadEn),
    .instruction_memory_a(rom_programCounter),
    .instruction_memory_v(rom_instruction)
);


endmodule
