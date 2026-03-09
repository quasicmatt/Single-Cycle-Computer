module scc_f25_top(
        input clk,
        input rst,
        input clk_en,
        output halt_f,
        output [1:0] err_bits,
        output [31:0] instruction_memory_v,
        output [31:0] data_memory_in_v
    );

    wire instruction_memory_en;
    wire data_memory_read;
    wire data_memory_write;
    wire [31:0] instruction_memory_a;
    wire [31:0] data_memory_a;
    wire [31:0] data_memory_out_v;

    scc scc(
        .clk(clk),
        .rst(rst),
        .halt_f(halt_f),
        .data_memory_read(data_memory_read),
        .data_memory_write(data_memory_write),
        .instruction_memory_v(instruction_memory_v),
        .data_memory_in_v(data_memory_in_v),
        .data_memory_out_v(data_memory_out_v),
        .data_memory_a(data_memory_a),
        .memReadEn(instruction_memory_en),
        .programCounter(instruction_memory_a)
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
        .data_memory_in_v(data_memory_in_v),
        .halt_f(halt_f)
        );


endmodule
