/*
TO RUN THIS TESTBENCH:
  1) Ensure you have compiled the SCC design files along with this testbench.
    iverilog -g2005 -o scc_tb.out scc_tb.v scc_f25_top.v scc.v instruction_and_data.v exe.v id.v inf.v mem.v regs.v wb.v alu.v rom.v
    vvp scc_tb.out

  2) Ensure that the SCC design writes its memory contents to "memory_dump.mem" at HALT using $writememh

  3) Ensure that you have a "dataoutput.csv" file in the same directory, containing
     the expected memory contents from the Emulator

  4) Run the simulation. The testbench will compare the dumped memory to the CSV file
     and report PASS or FAIL.
*/

`timescale 1ns/1ns

module scc_tb;

  localparam MEM_BYTES = 1<<16; // memory size in bytes (64KB)

  // DUT signals controlled by testbench
  reg clk_tb = 0; // clock signal
  reg rst_tb = 1; // active high reset set at start
  reg clk_en_tb = 1; // clock enable

  // DUT output signals monitored by testbench
  wire halt_f_tb; 
  wire [1:0] err_bits_tb; 
  wire [31:0] instruction_memory_v_tb;
  wire [31:0] data_memory_in_v_tb; 

  // instantiate the SCC DUT
  scc_f25_top dut (
    .clk(clk_tb),
    .rst(rst_tb),
    .clk_en(clk_en_tb),
    .halt_f(halt_f_tb),
    .err_bits(err_bits_tb),
    .instruction_memory_v(instruction_memory_v_tb),
    .data_memory_in_v(data_memory_in_v_tb)
  );

  always #5 clk_tb = ~clk_tb; // clock generation

  // release reset after 3 clock cycles
  initial begin
    repeat (3) @(posedge clk_tb);
    rst_tb = 1'b0;
  end

  reg [7:0] dut_mem [0:MEM_BYTES-1]; // memory array to hold DUT memory dump

  // dump VCD file for waveform viewing
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, scc_tb);
  end

  // compare memory dump to CSV file
  initial begin : COMPARE
    integer fd,fd2; // file descriptors
    integer matched,matched2; // sscanf return values
    integer line_num; // current line number in CSV file
    reg [255:0] line,line2; // buffers to hold each line from files
    reg [31:0] addr, value,addr2,value2; // parsed address and value from files
    reg [31:0] got_word; // word read from DUT memory

    // wait until HALT from the SCC
    wait(halt_f_tb);
    $display("Apollo has Landed!"); 
    @(posedge clk_tb);  // wait a clock after HALT to let $writememh finish in instruction_and_data

    // load SCC memory dump file
    //$readmemh("scc_out.txt", dut_mem);


    
    fd2 = $fopen("scc_out.txt", "r"); // open memory dump file
    if (fd2 == 0) begin // check for file open error
      $display("ERROR: could not open scc_out.txt");
      $finish;
    end

    // open CSV file
    fd = $fopen("dataoutput.csv", "r"); // open expected data file
    if (fd == 0) begin // check for file open error
      $display("ERROR: could not open dataoutput.csv");
      $finish; 
    end
    
    matched = $fgets(line, fd);  // read and ignore top line in dataoutput file from emulator
    matched2 = $fgets(line2,fd2); // read and ignore top line in scc_out file
    
    // tolerate optional spaces and optional 0x prefixes
    matched2 = $sscanf(line2, "0x%h , 0x%h", addr2, value2); // try to parse line
    if (matched2 != 2) matched2 = $sscanf(line2, "0x%h,0x%h", addr2, value2); // try without space
    if (matched2 != 2) matched2 = $sscanf(line2, "%h , %h",  addr2, value2); // try without 0x
    if (matched2 != 2) matched2 = $sscanf(line2, "%h,%h",    addr2, value2); // try without 0x and space
    
    line_num = 1; // start at line 1 (after header)
    // read each line of CSV file
    while (!$feof(fd)) begin
      line_num = line_num + 1;
      if ($fgets(line, fd)) begin

        // tolerate optional spaces and optional 0x prefixes
        matched = $sscanf(line, "0x%h , 0x%h", addr, value); // try to parse line
        if (matched != 2) matched = $sscanf(line, "0x%h,0x%h", addr, value); // try without space
        if (matched != 2) matched = $sscanf(line, "%h , %h",  addr, value); // try without 0x
        if (matched != 2) matched = $sscanf(line, "%h,%h",    addr, value); // try without 0x and space

        if (matched == 2) begin // if successfully parsed address and value
        
          while(addr!=addr2) begin // sync up addresses between files
            
            if($fgets(line2,fd2)) begin // read next line from scc_out file
              // tolerate optional spaces and optional 0x prefixes
              matched2 = $sscanf(line2, "0x%h , 0x%h", addr2, value2);
              if (matched2 != 2) matched2 = $sscanf(line2, "0x%h,0x%h", addr2, value2);
              if (matched2 != 2) matched2 = $sscanf(line2, "%h , %h",  addr2, value2);
              if (matched2 != 2) matched2 = $sscanf(line2, "%h,%h",    addr2, value2);
            end
          end
              matched2 = $sscanf(line2, "0x%h , 0x%h", addr2, value2);
              if (matched2 != 2) matched2 = $sscanf(line2, "0x%h,0x%h", addr2, value2);
              if (matched2 != 2) matched2 = $sscanf(line2, "%h , %h",  addr2, value2);
              if (matched2 != 2) matched2 = $sscanf(line2, "%h,%h",    addr2, value2);
          if ((addr+3) >= MEM_BYTES) begin // ensure we don't go out of bounds of memory range
            $display("FAIL @ line %0d: addr 0x%08h out of range", line_num, addr);
            $finish;
          end
          // assemble word: MSB at lowest address (matches your mem read logic)
          got_word = {dut_mem[addr+0], dut_mem[addr+1], dut_mem[addr+2], dut_mem[addr+3]}; 
          if (value2 !== value) begin // mismatch found
            $display("FAIL @ line %0d: addr=0x%08h got=0x%08h exp=0x%08h",
                     line_num, addr, value2, value); // show fail message and mismatched value and address
            $finish;
          end
          else begin
             $display("Passed @ line %0d: addr=0x%08h got=0x%08h exp=0x%08h",
                     line_num, addr, value2, value); // show pass message and matched value and address
          end
        end
        
      end
    end

    $display("PASS: all CSV memory values match DUT dump."); // if we reach here, all values matched
    $fclose(fd); // close the CSV file
    $fclose(fd2); // close the scc_out file
    $finish; // end simulation
  end

endmodule
