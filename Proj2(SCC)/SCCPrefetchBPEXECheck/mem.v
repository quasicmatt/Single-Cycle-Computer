module mem(
    input load_Flag,
    input store_Flag,
    input [31:0] alu_Result,
    output reg [31:0] mem_destination,
    output reg memRead,
    output reg memWrite
);


always @(*) begin
    memRead<=0;
    memWrite<=0;
    mem_destination <= alu_Result;
    if(load_Flag) begin
        memRead<=1;
        memWrite<=0;
    end
    else if(store_Flag) begin
        memRead<=0;
        memWrite<=1;
    end
    else begin
        memRead<=0;
        memWrite<=0;
    end
    
end
endmodule
