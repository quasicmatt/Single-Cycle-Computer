`timescale 1ps/1ps


module kadane_tb();

//Call all our inputs as registers
reg clk;
reg rst; 
reg clk_en; 

reg seen_halt;


//Call all our outputs as wires
wire halt_f; 
wire [1:0] err_bits; 
wire [31:0] instruction_memory_v; 
wire [31:0] data_memory_in_v; 

//Initialize module: 
scc_f25_top topMod (
    .clk(clk),
    .clk_en(clk_en), 
    .rst(rst), 
    .halt_f(halt_f), 
    .err_bits(err_bits), 
    .instruction_memory_v(instruction_memory_v), 
    .data_memory_in_v(data_memory_in_v)
); 


//Define clk action
always begin 
    clk = 1; 
    #5;
    clk = 0; 
    #5;
end

// Regs for Self Checking Test
reg[31:0] correct_value;
reg[31:0] test_output;

//Parsing sequence for scc_out.txt ALL CREDIT TO GROUP 1
integer fd, mem;
reg [31:0] addr, value;
reg [255:0] line; 

always @(posedge clk or posedge rst) begin //Problem here is that halt_f doesn't stay on long enough for wait to see. So we captured halt_f to use
  if (rst) seen_halt <= 1'b0;
  else if (halt_f) seen_halt <= 1'b1;
end

//Define kadane_tb action
initial begin 
    $dumpfile("dump.vcd");
    $dumpvars(0, kadane_tb);
    rst = 1; 
    clk_en = 1; 

    repeat (3) @(posedge clk);
    //Keep rst high for 3 clks
    rst = 0; 
    repeat (60) @(posedge clk);

    wait (seen_halt == 1);
    @(posedge clk);
    $display("\nAll quiet on the western front!\n");
    
    correct_value = 32'h00000037;
    test_output = 32'h00000000;
    
    fd = $fopen("scc_out.txt", "r");
        if (fd == 0) begin
            $display("TEST FAILED: Could not find scc_out.txt.");
            $finish;
        end

    // Skip first line (ALgorithim below credit to Group 1)
    line = ($fgets(line, fd));
    while ($fgets(line, fd)) begin
        mem = $sscanf(line, "0x%h,0x%h", addr, value);
        if (mem == 2) begin
            if (addr == 32'h00000500) begin
                test_output = value;
            end
        end
    end

    // Self-checking
    if (correct_value == test_output) begin
        $display("TEST PASSED: Kadane ALG SUCCESS");
    end else begin
        $display("TEST FAILED: NOOOOOOOOO");
    end
        $display("Expected Value: 0x00000037");
        $display("Actual Value: 0x%h\n", test_output);
    $finish; 
    
end

endmodule