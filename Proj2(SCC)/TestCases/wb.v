module wb(
    input [31:0] data_memory_in_v,
    input [31:0] alu_Result,
    input load_Flag,
    input clear_flag,
    input set_flag,
    input immediate_Flag,
    input romRegWrite_flag,
    input [1:0] mov_Flag,
    input [31:0] reg_in,
    input [15:0] imm_in,
    input [31:0] flag_Extended,
    output reg [31:0] output_Data,
    output reg [31:0] romoutput_Data
);


always @(*) begin
    if(romRegWrite_flag) begin
        case(mov_Flag)
            0:
            //no mov
                if(load_Flag) begin
                    romoutput_Data <= data_memory_in_v;
                end
                else if(clear_flag) begin
                    romoutput_Data <= 0;
                end
                else if(set_flag) begin
                    romoutput_Data <= 32'hFFFFFFFF;
                end
                else begin
                    romoutput_Data <= alu_Result;
                end
            1:
            //mov
                if(immediate_Flag) begin
                    romoutput_Data <= {{16'b0}, imm_in};
                end
                else begin
                    romoutput_Data <= reg_in;
                end
            2:
            //movt
                romoutput_Data <= {imm_in, {16'b0}};
            3:
            //movf
                romoutput_Data <= flag_Extended;
        endcase
    end

    else begin
        case(mov_Flag)
            0:
            //no mov
                if(load_Flag) begin
                    output_Data <= data_memory_in_v;
                end
                else if(clear_flag) begin
                    output_Data <= 0;
                end
                else if(set_flag) begin
                    output_Data <= 32'hFFFFFFFF;
                end
                else begin
                    output_Data <= alu_Result;
                end
            1:
            //mov
                if(immediate_Flag) begin
                    output_Data <= {{16'b0}, imm_in};
                end
                else begin
                    output_Data <= reg_in;
                end
            2:
            //movt
                output_Data <= {imm_in, {16'b0}};
            3:
            //movf
                output_Data <= flag_Extended;
        endcase
    end
end

endmodule
