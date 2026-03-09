/*******************************************************************************
 * Processor Testbench
 * 
 * This testbench validates the processor by:
 * 1. Instantiating the top-level processor module
 * 2. Generating clock and reset signals
 * 3. Running the processor until halt or timeout (100,000 cycles)
 * 4. Checking memory contents against expected values
 * 5. Reporting pass/fail status
 *
 * Test Validation:
 * After the processor halts, the testbench reads "scc_out.txt" (memory dump)
 * and verifies that three specific memory locations contain expected values:
 * - Address 0x00000404 should contain 0x000002EE
 * - Address 0x00000408 should contain 0x000007D0
 *
 * Waveform Generation:
 * Creates "testbench.vcd" file for viewing simulation waveforms with GTKWave
 * or similar tools. Dumps all testbench signals and all 16 registers.
 ******************************************************************************/

module scc_encrypt_tb;
    /***************************************************************************
     * Testbench Signals
     ***************************************************************************/
    reg clk_t, rst_t, clk_en_t;           // Control signals
    wire halt_f_t;                        // Halt flag from processor
    wire [1:0] error_indicator_t;         // Error flags from processor
    wire [31:0] instruction_memory_v_t;   // Current instruction (for monitoring)
    wire [31:0] data_memory_in_v_t;       // Data memory input (for monitoring)

    /***************************************************************************
     * Device Under Test (DUT) Instantiation
     * Connect testbench signals to the top-level processor module
     ***************************************************************************/
    scc_f25_top CompToTest(
        .clk(clk_t), 
        .clk_en(clk_en_t), 
        .rst(rst_t), 
        .halt_f(halt_f_t), 
        .err_bits(error_indicator_t), 
        .instruction_memory_v(instruction_memory_v_t), 
        .data_memory_in_v(data_memory_in_v_t)
    );
    
    /***************************************************************************
     * Test Variables
     ***************************************************************************/
    integer cycles = 0;          // Cycle counter for timeout and reporting
    integer file, status;        // File handle and I/O status
    reg [8*100:1] line;          // Buffer for reading file lines (100 chars)
    reg [31:0] addr, value;      // Parsed address and value from file
    reg[1:0] test_passed;        // Bit vector tracking which tests passed
    integer found_addr;          // Flag indicating if target address found
    integer parse_error;         // Flag indicating file parsing error
    integer i;                   // Loop variable

    /***************************************************************************
     * Clock Generation and Test Execution
     * 
     * Clock Period: 20ns (10ns low, 10ns high) = 50MHz
     * 
     * This block:
     * 1. Generates a free-running clock
     * 2. Counts cycles
     * 3. Detects halt or timeout condition
     * 4. Validates memory contents after halt
     * 5. Reports test results
     ***************************************************************************/
    always begin
        clk_t <= 0;
        #10;                     // 10ns low phase
        clk_t <= 1;
        #10;                     // 10ns high phase
        cycles = cycles + 1;     // Increment cycle counter
        
        /*********************************************************************
         * Halt or Timeout Detection
         * Test ends when:
         * - halt_f_t asserts (processor executed HALT instruction)
         * - 100,000 cycles reached (timeout to catch infinite loops)
         *********************************************************************/
        if (halt_f_t || cycles == 100000) begin
            // Wait for memory dump file to be written
            #20;
            
            /*****************************************************************
             * Open Memory Dump File
             * The processor writes memory contents to "scc_out.txt" on halt
             *****************************************************************/
            file = $fopen("scc_out.txt", "r");
            if (file == 0) begin
                $display("ERROR: Could not open scc_out.txt");
                $finish;
            end
            
            /*****************************************************************
             * Skip CSV Header Line
             * File format: "Address,Value" header followed by data lines
             *****************************************************************/
            status = $fgets(line, file);
            
            /*****************************************************************
             * Initialize Test Tracking Variables
             *****************************************************************/
            test_passed = 0;      // No tests passed yet
            found_addr = 0;       // Haven't found final address yet
            parse_error = 0;      // No parsing errors yet
            
            /*****************************************************************
             * Parse Memory Dump and Validate Expected Values
             * Read each line until EOF or until all tests are evaluated
             *****************************************************************/
            while (!$feof(file) && !found_addr && !parse_error) begin
                // Parse address and value in hex format: "0xAAAAAAAA,0xVVVVVVVV"
                status = $fscanf(file, "0x%h,0x%h\n", addr, value);
                
                // Check for parse errors
                if (status != 2) begin
                    $display("ERROR: Could not parse data line in scc_out.txt");
                    parse_error = 1;
                end
                
                /*********************************************************
                 * TEST 1: Check Address 0x00000404
                 * Expected value: 0x00000040
                 *********************************************************/
                else if (addr == 32'h00000404) begin
                    if (value == 32'h00000040) begin
                        $display("TEST 1 PASSED: Address 0x00000404 contains 0x00000040");
                        test_passed[0] = 1;
                    end else begin
                        $display("TEST FAILED: Expected Value=0x00000040 at Address 0x00000404");
                        $display("             Got Value=0x%08h", value);
                        test_passed[0] = 0;
                    end
                end
                
                /*********************************************************
                 * TEST 2: Check Address 0x00000408
                 * Expected value: 0x00000039
                 *********************************************************/
                else if (addr == 32'h00000408) begin
                    found_addr = 1;
                    if (value == 32'h00000039) begin
                        $display("TEST 2 PASSED: Address 0x00000408 contains 0x00000039");
                        test_passed[1] = 1;
                    end else begin
                        $display("TEST 2 FAILED: Expected Value=0x00000039 at Address 0x00000408");
                        $display("             Got Value=0x%08h", value);
                        test_passed[1] = 0;
                    end
                end
            end
            
            /*****************************************************************
             * Handle Error Conditions
             *****************************************************************/
            if (parse_error) begin
                test_passed = 2'b00;  // All tests fail on parse error
            end else if (!found_addr) begin
                $display("TEST FAILED: Address 0x00000412 not found in scc_out.txt");
            end
            
            // Close the file
            $fclose(file);
            
            /*****************************************************************
             * Report Final Results
             * test_passed == 3'b111 means all three tests passed
             *****************************************************************/
            $display("\n========================================");
            $display("Total cycles: %0d", cycles);
            if (test_passed == 2'b11)
                $display("RESULT: PASS");
            else
                $display("RESULT: FAIL");
            $display("========================================\n");
            
            // End simulation
            $finish;
        end
    end

    /***************************************************************************
     * Initialization and Waveform Dump Setup
     * 
     * This initial block:
     * 1. Sets up VCD (Value Change Dump) file for waveform viewing
     * 2. Dumps all testbench signals
     * 3. Dumps all 16 processor registers for detailed debugging
     * 4. Generates reset sequence
     * 5. Enables the clock
     ***************************************************************************/
    initial begin
        /*********************************************************************
         * Waveform Dump Configuration
         * Creates "testbench.vcd" for viewing with GTKWave or similar tools
         *********************************************************************/
        $dumpfile("dump.vcd");
        $dumpvars(0, scc_encrypt_tb);  // Dump all testbench signals
        
        /*********************************************************************
         * Register Dump Configuration
         * Explicitly dump all 16 general-purpose registers (X0-X15)
         * This allows detailed inspection of register values during debug
         *********************************************************************/
        // $dumpvars(0, testbench.CompToTest.core.registers.rX[0]);
        // $dumpvars(0, testbench.CompToTest.core.registers.rX[1]);
        // $dumpvars(0, testbench.CompToTest.core.registers.rX[2]);
        // $dumpvars(0, testbench.CompToTest.core.registers.rX[3]);
        // $dumpvars(0, testbench.CompToTest.core.registers.rX[4]);
        // $dumpvars(0, testbench.CompToTest.core.registers.rX[5]);
        // $dumpvars(0, testbench.CompToTest.core.registers.rX[6]);
        // $dumpvars(0, testbench.CompToTest.core.registers.rX[7]);
        // $dumpvars(0, testbench.CompToTest.core.registers.rX[8]);
        // $dumpvars(0, testbench.CompToTest.core.registers.rX[9]);
        // $dumpvars(0, testbench.CompToTest.core.registers.rX[10]);
        // $dumpvars(0, testbench.CompToTest.core.registers.rX[11]);
        // $dumpvars(0, testbench.CompToTest.core.registers.rX[12]);
        // $dumpvars(0, testbench.CompToTest.core.registers.rX[13]);
        // $dumpvars(0, testbench.CompToTest.core.registers.rX[14]);
        // $dumpvars(0, testbench.CompToTest.core.registers.rX[15]);  // PC
        
        /*********************************************************************
         * Reset Sequence
         * 1. Assert reset (rst_t = 1)
         * 2. Wait 3 clock cycles
         * 3. Deassert reset (rst_t = 0)
         * 4. Enable clock (clk_en_t = 1) to start processor execution
         *********************************************************************/
        rst_t <= 1;
        repeat(3) @(posedge clk_t);  // Wait for 3 clock edges
        rst_t <= 0;                  // Release reset
        clk_en_t <= 1;               // Enable processor operation
    end
endmodule