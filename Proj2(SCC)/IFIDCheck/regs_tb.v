`timescale 1ns/1ns

module regs_tb();
    reg clk_tb, rst_tb, write_to_reg_Flag_tb;
    reg [3:0] write_reg_tb, read_reg_1_tb, read_reg_2_tb;
    reg [31:0] write_data_tb;
    wire halt_f_tb;
    wire [31:0] read_data_1_tb, read_data_2_tb;

    initial begin
        clk_tb <= 0;
        rst_tb <= 0;
        write_to_reg_Flag_tb <= 0;
        write_reg_tb <= 0;
        read_reg_1_tb <= 0;
        read_reg_2_tb <= 0;
        write_data_tb <= 0;
        $dumpfile("dumpRegs.vcd");
        $dumpvars(0, regs_tb);
    end

    always @(posedge clk_tb) begin
        if(halt_f_tb) begin
            $finish;
        end
    end

    regs regs_test (
        .clk(clk_tb),
        .rst(rst_tb),
        .write_to_reg_Flag(write_to_reg_Flag_tb),
        .write_reg(write_reg_tb),
        .read_reg_1(read_reg_1_tb),
        .read_reg_2(read_reg_2_tb),
        .write_data(write_data_tb),
        .read_data_1(read_data_1_tb),
        .read_data_2(read_data_2_tb),
        .halt_f(halt_f_tb)
    );

    always begin
        #10 clk_tb = ~clk_tb;
    end

    initial begin

        #10 rst_tb <= 1;
        #58;
        rst_tb <= 0;
        write_data_tb <= 'hFFFF0000;
        write_reg_tb <= 5;
        read_reg_1_tb <= 5;
        read_reg_2_tb <= 5;
        write_to_reg_Flag_tb <= 1;
        #20
        write_data_tb <= 'hCCCC0000;
        write_reg_tb <= 3;
        read_reg_2_tb <= 3;
        #20
        write_to_reg_Flag_tb <= 0;
        write_reg_tb <= 5;
        #160;
        $finish;

    end

endmodule
