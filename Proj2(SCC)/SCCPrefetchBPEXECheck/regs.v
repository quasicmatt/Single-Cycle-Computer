module regs(
    input clk,
    input rst,
    input write_to_reg_Flag,
    input [3:0] write_reg,
    input [3:0] read_reg_1,
    input [3:0] read_reg_2,
    input [31:0] write_data,
    output [31:0] read_data_1,
    output [31:0] read_data_2,
    output reg [31:0] store_data
    //,output halt_f // this is only for regs_tb.v
    );

reg [31:0] regs[0:14]; //32 bit wide with a depth of 16 (for registers 0-14)
reg [31:0] read_data_1, read_data_2;
initial regs[14] = 0; //initialize 0 register

always @(*) begin
    read_data_1 = regs[read_reg_1]; //reading the associated register number
    read_data_2 = regs[read_reg_2];
    store_data = regs[write_reg];
end

always@(posedge clk) begin
    if (rst == 0) begin
        if (write_to_reg_Flag == 1 && write_reg != 14) begin //prevent writing to reg 14
            regs[write_reg] = write_data; //if write_Flag is enabled, write the input data to the chosen register
        end
        else begin
            regs[write_data] = regs[write_data]; //if write_Flag is disabled, the chosen register saves its current value
        end
    end
    else begin
        {regs[0], regs[1], regs[2], regs[3], regs[4], regs[5], regs[6], regs[7], regs[8], regs[9], regs[10], regs[11], regs[12], regs[13], regs[14]} = 0; //sets all regs to 0
    end
    
end

endmodule