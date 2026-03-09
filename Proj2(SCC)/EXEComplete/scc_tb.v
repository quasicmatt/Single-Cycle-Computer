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

  // clock generation
  always #5 clk_tb = ~clk_tb;

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
    integer fd; // file descriptor for CSV file
    integer matched; // number of items matched by sscanf
    integer line_num; // current line number in CSV file
    reg [255:0] line; // buffer to hold each line from CSV file
    reg [31:0] addr, value; // address and expected value from CSV file
    reg [31:0] got_word; // word read from DUT memory

    // wait until HALT from the SCC
    wait(halt_f_tb);
    $display("Apoll has Landed!"); // when halted "Apoll" has landed, program complete
    @(posedge clk_tb);  // wait a clock after HALT to let $writememh finish in instruction_and_data

    // load SCC memory dump file
    $readmemh("memory_dump.mem", dut_mem);

    // open CSV file
    fd = $fopen("dataoutput.csv", "r"); 
    if (fd == 0) begin // check for file open error
      $display("ERROR: could not open dataoutput.csv"); // show error message
      $finish; // end simulation
    end
    
    matched = $fgets(line, fd);  // read and ignore top line in dataoutput file

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
          
          if ((addr+3) >= MEM_BYTES) begin // ensure we don't go out of bounds of memory range
            $display("FAIL @ line %0d: addr 0x%08h out of range", line_num, addr); // show fail message and address
            $finish; // end simulation
          end
          // assemble word: MSB at lowest address (matches your mem read logic)
          got_word = {dut_mem[addr+0], dut_mem[addr+1], dut_mem[addr+2], dut_mem[addr+3]};
          // compare to expected value
          if (got_word !== value) begin // mismatch found
            $display("FAIL @ line %0d: addr=0x%08h got=0x%08h exp=0x%08h",
              line_num, addr, got_word, value); // show fail message and mismatched value and address
            $finish; // end simulation
          end
        end
        
      end
    end

    $display("PASS: all CSV memory values match DUT dump."); // if we reach here, all values matched
    $fclose(fd); // close the CSV file
    $finish; // end simulation
  end

endmodule
