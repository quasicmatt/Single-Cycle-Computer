/* this should work for any group that adheres to the following two conditions: 
* 1) Your instruction_and_data.v produces a file named scc_out.txt at HALT.
* 2) The produced scc_out.txt follows the format of 
*           Address,Value
*           0x00000000,0x00 ... 
* just as the Emulator CSV does. 
*/
`timescale 1ns/1ns

module scc_tb_simple_crc();

    // dump waveform event
    integer i;
    event START_LOG;

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, scc_tb_simple_crc);
    end

    // core clock and reset
    reg clk = 0;
    reg rst = 0;
    reg clk_en = 1;
    wire halt_f;
    wire [1:0] err_bits;
    wire [31:0] instruction_memory_v;
    wire [31:0] data_memory_in_v;
    
    // Local variables for the self-checking logic
    integer error_count = 0;
    reg [31:0] expected_value;  // updates as we go for the 2 tests
    reg [31:0] actual_value;    // updates as we go for the 2 tests
    reg [15:0] current_address; // used to clarify current address and for printing 

    reg [31:0] initial_value;   // this can me modified in this tb and the asm file to test other values. 
    reg [31:0] expected_checksum;   // uses calculating function to produce
    
    always #5 clk = ~clk;

    // Instantiate the DUT for top module
    scc_f25_top top(
        .clk(clk),
        .rst(rst),
        .clk_en(clk_en),
        .halt_f(halt_f),
        .err_bits(err_bits),
        .instruction_memory_v(instruction_memory_v),
        .data_memory_in_v(data_memory_in_v)
    );

    // Original six words from the assembly Data_Block
    reg [31:0] data_block [0:5];
    initial begin
        data_block[0] = 32'hDEADBEEF;
        data_block[1] = 32'h12345678;
        data_block[2] = 32'h90ABCDEF;
        data_block[3] = 32'h00000000;
        data_block[4] = 32'h87654321;
        data_block[5] = 32'h0F0F0F0F;
    end

    // Checksum calculator! (Self Checking)      
    function [31:0] compute_checksum;
        input [31:0] init_val;
        integer j;
        reg [31:0] R1, R2, R4, R5, R6;
    begin
        R1 = init_val;
        // Manually use the global data_block array
        for (j = 0; j < 6; j = j + 1) begin
            R2 = data_block[j];
            R1 = R1 ^ R2;
            R4 = R2 >> 3;
            R5 = R2 << 5;
            R6 = R4 & R5;
            R1 = R1 ^ R6;
        end
        compute_checksum = R1;
    end
    endfunction
    
    // for parsing scc_out.txt
    integer fd, matched, line_num;  // internal variable used to read file line by line and ensure regex formatting matches 
    reg [31:0] addr, value;         // key value pairs for scc_out.txt (the emulator's CSV uses the same format)
    reg [31:0] dut_checksum_val, dut_revert_val;    // YOUR SCC's COMPUTED VALUES from running the simple_crc.asm
    integer found_checksum, found_revert;           // if values were found at the intended memory locations 
    reg [255:0] dummy_line;                         // skip header line "Address,Value"

    // --- TEST CASE SEQUENCE --- 
    initial begin
        $display("Starting LOGIC_CHECKSUM Testbench...");      

        #10 rst = 1;
        #30; // rst active for 3 clocks
        rst = 0;

        // Wait for the processor to halt before checking memory
        wait (halt_f == 1);
        $display("Apollo has Landed!");
        @(posedge clk);   // allow instruction_and_data to write to scc_out.txt

        // ===============================================================
        // ==  READ AND PARSE scc_out.txt                               ==
        // ===============================================================
        /* Note, scc_out.txt begins with line "Address,Value" */
        found_checksum = 0;
        found_revert   = 0;
        dut_checksum_val   = 32'hXXXXXXXX;
        dut_revert_val     = 32'hXXXXXXXX;
        dummy_line = 0;

        fd = $fopen("scc_out.txt", "r");
        if (fd == 0) begin
            $display("ERROR: Could not open scc_out.txt");
            $finish;
        end

        // Skip header line "Address,Value"
        dummy_line = $fgets(dummy_line, fd);
        line_num = 1;

        // Read file line-by-line
        while ($fgets(dummy_line, fd)) begin
            matched = $sscanf(dummy_line, "0x%h,0x%h", addr, value);
            if (matched == 2) begin
                if (addr == 32'h0000D51C) begin
                    dut_checksum_val = value;
                    found_checksum = 1;
                end else if (addr == 32'h0000D520) begin
                    dut_revert_val = value;
                    found_revert = 1;
                end
            end
        end

        // if those memory addresses were never found by the parser 
        if (!found_checksum) begin
            $display("ERROR: Could not locate address 0xD51C in scc_out.txt");
            $finish;
        end
        if (!found_revert) begin
            $display("ERROR: Could not locate address 0xD520 in scc_out.txt");
            $finish;
        end
        $fclose(fd);

        //======================================================================//
        //==             CHECKSUM RESULT VALIDATION                           ==//
        //======================================================================//

        $display("\n--- Checking Final Checksum & Revert back to Original Form in Memory ---");


        /* This is the initial value to be check summed & then reverted back to normal form. */
        /* This is set in SET R1 in the simple_crc.asm file. if another value is intended to be started with, */
        /* you can use MOV R1, #immedaite instead to test different CRCs and their results. */
        initial_value = 32'hFFFFFFFF;
        // returns the expected check sum, logical folding across 7 words in memory. 
        expected_checksum = compute_checksum(initial_value);
        // should result in 32'h29687109 if starting with 32'hFFFFFFFF  


        // Compare 32-bit checksum value from 0xD51c–0xD51F
        current_address = 16'hD51c;
        actual_value = dut_checksum_val;   // obtained from scc_out.txt above  
        expected_value = expected_checksum;

        if (actual_value == expected_value) begin
            // \033[1;32m = green color, \033[0m = red color
            $display("\033[1;32m  [PASS]\033[0m Checksum @ 0x%h | Expected: 0x%h | Got: 0x%h",
                    current_address, expected_value, actual_value);
        end else begin  // actual value does not match expected checksum
            $display("\033[1;31m>> [FAIL]\033[0m Checksum @ 0x%h | Expected: 0x%h | Got: 0x%h",
                    current_address, expected_value, actual_value);
            error_count = error_count + 1;
        end
                

        // Compare 32-bit Original (undid the checksum) value from 0xD520–0xD523
        current_address = 16'hD520;
        actual_value = dut_revert_val; // obtained from scc_out.txt above  
        expected_value = initial_value;

        if (actual_value == expected_value) begin
            $display("\033[1;32m  [PASS]\033[0m Undo Check Sum, Revert to Original Value @ 0x%h | Expected: 0x%h | Got: 0x%h",
                    current_address, expected_value, actual_value);
        end else begin  // actual value does not match expected reverted checksum value 
            $display("\033[1;31m>> [FAIL]\033[0m Undo Check Sum, Revert to Original Value @ 0x%h | Expected: 0x%h | Got: 0x%h",
                    current_address, expected_value, actual_value);
            error_count = error_count + 1;
        end

        $display("----------------------------------------------------");
        if (error_count == 0) begin
            $display("\033[1;32m  TEST PASSED! \033[0m Checksum output matches expected value.");
        end else begin
            $display("\033[1;31m>> TEST FAILED! \033[0m Found %0d mismatch(es).", error_count);
        end
        

        $display("[%0t] Halt signal detected. Test sequence complete.", $time);
        $finish;
    end

endmodule