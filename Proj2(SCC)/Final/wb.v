module wb(
    input [31:0] data_memory_in_v, //Read from data memory
    input [31:0] alu_Result, //Result from ALU
    input load_Flag, //Tells if there is a load
    input clear_flag, //Tells if register should be cleared
    input set_flag, //Tells if register should be set
    input immediate_Flag, //Tells if it is an immediate instruction
    input romRegWrite_flag, //Tells if only rom registers should be written to
    input [1:0] mov_Flag, //Tells which mov instruction if any is being performed
    input [31:0] reg_in, //value from input register
    input [15:0] imm_in, //Immediate from instruction
    input [31:0] flag_Extended, //Flag values
    output reg [31:0] output_Data, //Output to register module
    output reg [31:0] romoutput_Data //Ouptut to rom registers
);


always @(*) begin
    if(romRegWrite_flag) begin //Writing to rom register for microcode
        case(mov_Flag)
            0:
            //no mov
                if(load_Flag) begin
                    romoutput_Data <= data_memory_in_v; //Loads save output from data memory to register
                end
                else if(clear_flag) begin
                    romoutput_Data <= 0; //Clear sets register to 0
                end
                else if(set_flag) begin
                    romoutput_Data <= 32'hFFFFFFFF; //Set sets register to all 1s
                end
                else begin
                    romoutput_Data <= alu_Result; //Sets register to ALU value
                end
            1:
            //mov
                if(immediate_Flag) begin
                    romoutput_Data <= {{16'b0}, imm_in}; //Sets bottom 16 bits to the immediate value
                end
                else begin
                    romoutput_Data <= reg_in; //Sets register as the value of a register
                end
            2:
            //movt
                romoutput_Data <= {imm_in, {16'b0}}; //Sets top 16 bits to the immediate value
            3:
            //movf
                romoutput_Data <= flag_Extended; //Saves flags to a register
        endcase
    end

    else begin //Writing to regular registers
        case(mov_Flag)
            0:
            //no mov
                if(load_Flag) begin
                    output_Data <= data_memory_in_v; //Loads save output from data memory to register
                end
                else if(clear_flag) begin
                    output_Data <= 0; //Clear sets register to 0
                end
                else if(set_flag) begin
                    output_Data <= 32'hFFFFFFFF; //Set sets register to all 1s
                end
                else begin
                    output_Data <= alu_Result; //Sets register to ALU value
                end
            1:
            //mov
                if(immediate_Flag) begin
                    output_Data <= {{16'b0}, imm_in}; //Sets bottom 16 bits to the immediate value
                end
                else begin
                    output_Data <= reg_in; //Sets register as the value of a register
                end
            2:
            //movt
                output_Data <= {imm_in, {16'b0}}; //Sets top 16 bits to the immediate value
            3:
            //movf
                output_Data <= flag_Extended; //Saves flags to a register
        endcase
    end
end

endmodule
