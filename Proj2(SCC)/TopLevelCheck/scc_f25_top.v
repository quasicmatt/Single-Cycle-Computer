module scc_f25_top(clk,rst,clk_en,halt_f,err_bits,instruction_memory_v,data_memory_in_v);

    input clk,rst,clk_en;
    output halt_f;
    output [1:0] err_bits;
    output [31:0] instruction_memory_v,data_memory_in_v;

    wire instruction_memory_en, data_memory_read, data_memory_write;
    wire [31:0] instruction_memory_a, data_memory_a, data_memory_out_v;

    scc scc(
        .clk(clk),
        .rst(rst),
        .halt_f(halt_f),
        .data_memory_read(data_memory_read),
        .data_memory_write(data_memory_write),
        .instruction_memory_v(instruction_memory_v),
        .data_memory_in_v(data_memory_in_v),
        .data_memory_a(data_memory_a)
    );

    instruction_and_data mem_module(
        .mem_Clk(clk),
        .instruction_memory_en(instruction_memory_en),
        .instruction_memory_a(instruction_memory_a),
        .data_memory_a(data_memory_a),
        .data_memory_read(data_memory_read),
        .data_memory_write(data_memory_write),
        .data_memory_out_v(data_memory_out_v),
        .instruction_memory_v(instruction_memory_v),
        .data_memory_in_v(data_memory_in_v)
        );


endmodule
