`timescale 1ns/1ns

module scc_tb();
    reg clk_tb,rst_tb,clk_en_tb;
    wire halt_f_tb;
    wire [1:0] err_bits_tb;
    wire [31:0] instruction_memory_v_tb,data_memory_in_v_tb;

    initial begin
        clk_tb <= 0;
        rst_tb <= 0;

        $dumpfile("dump.vcd");
        $dumpvars(0, scc_tb);
    end

    always @(posedge clk_tb) begin
        if(halt_f_tb) begin
            $finish;
        end
    end

    always begin
        #10 clk_tb = ~clk_tb;
    end

    scc_f25_top scc_top(
        .clk(clk_tb),
        .rst(rst_tb),
        .clk_en(clk_en_tb),
        .halt_f(halt_f_tb),
        .err_bits(err_bits_tb),
        .instruction_memory_v(instruction_memory_v_tb),
        .data_memory_in_v(data_memory_in_v_tb)
    );

    initial begin

        #10 rst_tb <= 1;
        #60;
        rst_tb <= 0;

        #30;
        $finish;

    end

endmodule
