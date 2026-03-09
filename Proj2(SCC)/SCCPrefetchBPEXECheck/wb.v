module wb(
    input [31:0] mem_data,
    input [31:0] alu_Result,
    input load_Flag,
    input immediate_Flag,
    input [1:0] mov_Flag,
    input [31:0] reg_in,
    input [15:0] imm_in,
    output reg [31:0] output_Data
);

always @(*) begin
    case(mov_Flag)
        0:
        //no mov
            if(load_Flag) begin
                output_Data <= mem_data;
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
        //2:
        //movt
        //3:
        //movf
    endcase
end

endmodule