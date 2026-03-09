`timescale 1ns / 1ps

module lut_tb;

    // Testbench signals
    reg clk;
    reg clk_en;
    reg rst;

    wire halt_f;
    wire [1:0] err_bits;
    wire [31:0] instruction_memory_v;
    wire [31:0] data_memory_in_v;

    // Instantiate the top-level DUT (Device Under Test)
    scc_f25_top dut (
        .clk(clk),
        .clk_en(clk_en),
        .rst(rst),
        .halt_f(halt_f),
        .err_bits(err_bits),
        .instruction_memory_v(instruction_memory_v),
        .data_memory_in_v(data_memory_in_v)
    );

    // Self-checking regs
    // Target values
    reg [31:0] target_v_1, target_v_2, target_v_3, target_v_4, target_v_5, target_v_6;
    // Actual values found in simulation
    reg [31:0] value1, value2, value3, value4, value5, value6;

    // Generate a clock (100MHz -> 10ns period)
    initial clk = 1;
    always #10 clk = ~clk;  // toggle every 5ns

    // Self-checking regs
    reg [31:0] dut_mem [0:16383];
    reg [31:0] expected_value;
    reg [31:0] actual_value;

    // Test sequence
    initial begin
        $dumpvars(0, lut_tb);

        // Explicltly dumping each register
        

        // Initialize
        clk_en = 1'b1;   // allow clocked logic
        rst    = 1'b1;   // assert reset
        #60;             // hold reset for 20ns

        rst    = 1'b0;   // release reset
        #1000;            // let the CPU run a few cycles

        wait (dut.halt_f == 1);
        @(posedge clk);
        
        $readmemh("scc_out.txt", dut_mem);
        
        expected_value = 32'h00000032;
        actual_value = dut_mem[100]; 
        
        // Self-checking
        if (actual_value === expected_value) begin
            $display("PASS: Memory[0x190] correctly contains %h.", actual_value);
        end else begin
            $display("FAIL: Memory[0x190] was incorrect.");
            $display("Expected: %h", expected_value);
            $display("Actual: %h", actual_value);
        end

        $finish;
    end

endmodule
