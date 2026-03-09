module regs(
    input clk,
    input rst,
    input write_to_reg_Flag,
    input [3:0] write_reg,
    input [3:0] read_reg_1,
    input [3:0] read_reg_2,
    input [31:0] write_data,
    input [1:0] mov_Flag,
    output [31:0] read_data_1,
    output [31:0] read_data_2,
    output reg [31:0] store_data,
    input romRegWriteFlag
    );

reg [31:0] regs[0:14]; //32 bit wide with a depth of 16 (for registers 0-14)
reg [31:0] read_data_1, read_data_2;
initial regs[14] = 0; //initialize 0 register
//this is to allow for the regs to be visable in gtkwave something about instantiating an array of regs it hates
wire [31:0] dbg_reg0,dbg_reg1,dbg_reg2,dbg_reg3,dbg_reg4,dbg_reg5,dbg_reg6,dbg_reg7,dbg_reg8,dbg_reg9,dbg_reg10,dbg_reg11,dbg_reg12,dbg_reg13,dbg_reg14;
assign dbg_reg0=regs[0];
assign dbg_reg1=regs[1];
assign dbg_reg2=regs[2];
assign dbg_reg3=regs[3];
assign dbg_reg4=regs[4];
assign dbg_reg5=regs[5];
assign dbg_reg6=regs[6];
assign dbg_reg7=regs[7];
assign dbg_reg8=regs[8];
assign dbg_reg9=regs[9];
assign dbg_reg10=regs[10];
assign dbg_reg11=regs[11];
assign dbg_reg12=regs[12];
assign dbg_reg13=regs[13];
assign dbg_reg14=regs[14];

wire [31:0] regData;
assign regData=regs[write_reg];

always @(*) begin
    read_data_1 = regs[read_reg_1]; //reading the associated register number
    read_data_2 = regs[read_reg_2];
    store_data = regs[write_reg];
end

always@(posedge clk) begin
    if (rst == 0) begin
        
        if(romRegWriteFlag==0) begin
            if (write_to_reg_Flag == 1 && write_reg != 14) begin //prevent writing to reg 14
                if (mov_Flag == 2) begin
                    regs[write_reg] = {write_data[31:16], regData[15:0]}; //For movt, lower bits 0
                end
                else begin
                    regs[write_reg] = write_data; //if write_Flag is enabled, write the input data to the chosen register
                end
            end
            else begin
                regs[write_data] = regs[write_data]; //if write_Flag is disabled, the chosen register saves its current value
            end
        end
        
    end
    else begin
        {regs[0], regs[1], regs[2], regs[3], regs[4], regs[5], regs[6], regs[7], regs[8], regs[9], regs[10], regs[11], regs[12], regs[13], regs[14]} = 0; //sets all regs to 0
    end
    
end

endmodule
