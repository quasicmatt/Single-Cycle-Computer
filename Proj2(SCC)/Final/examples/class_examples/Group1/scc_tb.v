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

    // Generate a clock (100MHz -> 10ns period)
    initial clk = 1;
    always #10 clk = ~clk;  // toggle every 5ns

    // Self-checking regs
    reg [31:0] expected_value;
    reg [31:0] actual_value;

    // for parsing scc_out.txt
    integer fd, mem;
    reg [31:0] addr, value;
    reg [255:0] line; 

    // Test sequence
    initial begin
        $dumpvars(0, lut_tb);

        // Initialize
        clk_en = 1'b1;   // allow clocked logic
        rst    = 1'b1;   // assert reset
        #60;             // hold reset for 20ns

        rst    = 1'b0;   // release reset
        #1000;            // let the CPU run a few cycles

        wait (dut.halt_f == 1);
        @(posedge clk);
        $display("\nApollo has landed!\n");
        
        expected_value = 32'h00000032;
        
        fd = $fopen("scc_out.txt", "r");
        if (fd == 0) begin
            $display("TEST FAILED: Could not find scc_out.txt.");
            $finish;
        end

        // Skip first line
        line = ($fgets(line, fd));
        // Read rest of scc_out.txt to find LUT result
        while ($fgets(line, fd)) begin
            mem = $sscanf(line, "0x%h,0x%h", addr, value);
            if (mem == 2) begin
                if (addr == 32'h00000190) begin
                    actual_value = value;
                end
            end
        end

        // Self-checking
        if (expected_value == actual_value) begin
            $display("TEST PASSED: LUT value match");
        end else begin
            $display("TEST FAILED: LUT value mismatch");
        end
            $display("Expected Value: 0x00000032");
            $display("Actual Value: 0x%h\n", actual_value);

        $finish;
    end

endmodule
