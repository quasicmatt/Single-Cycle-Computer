module mem(
    input load_Flag, //Flag to perform a load from data memory
    input store_Flag, //Flag to eprform a store to data memory
    input [31:0] alu_Result, //The result for address pointer
    output reg [31:0] mem_destination, //The pointer address to load from or store to
    output reg memRead, //Flag to update the read from data memory
    output reg data_memory_write //Flag to update the write to data memory
);


always @(*) begin
    memRead=0; //Don't read or write by default
    data_memory_write=0;
    mem_destination = alu_Result; //Stores the pointer
    if(load_Flag) begin //Flags for load
        memRead=1;
        data_memory_write=0;
    end
    else if(store_Flag) begin //Flags for store
        memRead=0;
        data_memory_write=1;
    end
    else begin //Default case for neither
        memRead=0;
        data_memory_write=0;
    end
    
end
endmodule
