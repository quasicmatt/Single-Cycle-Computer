/*
iverilog -g2005 -o scc_tb.out scc_tb.v scc_f25_top.v scc.v instruction_and_data.v exe.v id.v inf.v mem.v regs.v wb.v alu.v rom.v

vvp scc_tb.out 
*/
`timescale 1ns/1ns

module scc_tb;

  localparam MEM_BYTES = 1<<16;

  reg clk_tb = 1;
  reg rst_tb = 1;
  reg clk_en_tb = 1;

  wire halt_f_tb;
  wire [1:0] err_bits_tb;
  wire [31:0] instruction_memory_v_tb;
  wire [31:0] data_memory_in_v_tb;

  scc_f25_top dut (
    .clk(clk_tb),
    .rst(rst_tb),
    .clk_en(clk_en_tb),
    .halt_f(halt_f_tb),
    .err_bits(err_bits_tb),
    .instruction_memory_v(instruction_memory_v_tb),
    .data_memory_in_v(data_memory_in_v_tb)
  );

  always #5 clk_tb = ~clk_tb;

  // release reset after 3 clock cycles
  initial begin
    repeat (3) @(posedge clk_tb);
    rst_tb = 1'b0;
  end

  reg [7:0] dut_mem [0:MEM_BYTES-1];

  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, scc_tb);
  end

  // compare memory dump to CSV file
  initial begin : COMPARE
    integer fd,fd2;
    integer matched,matched2;
    integer line_num;
    reg [255:0] line,line2;
    reg [31:0] addr, value,addr2,value2;
    reg [31:0] got_word;

    // wait until HALT from the SCC
    wait(halt_f_tb);
    $display("Apollo has Landed!");
    @(posedge clk_tb);  // wait a clock after HALT to let $writememh finish in instruction_and_data

    // load SCC memory dump file
    //$readmemh("scc_out.txt", dut_mem);


    
    fd2 = $fopen("scc_out.txt", "r");
    if (fd2 == 0) begin
      $display("ERROR: could not open scc_out.txt");
      $finish;
    end

    // open CSV file
    fd = $fopen("dataoutput.csv", "r");
    if (fd == 0) begin
      $display("ERROR: could not open dataoutput.csv");
      $finish;
    end
    
    matched = $fgets(line, fd);  // read and ignore top line in dataoutput file
    matched2 = $fgets(line2,fd2);
    
    matched2 = $sscanf(line2, "0x%h , 0x%h", addr2, value2);
    if (matched2 != 2) matched2 = $sscanf(line2, "0x%h,0x%h", addr2, value2);
    if (matched2 != 2) matched2 = $sscanf(line2, "%h , %h",  addr2, value2);
    if (matched2 != 2) matched2 = $sscanf(line2, "%h,%h",    addr2, value2);
    
    line_num = 1;
    while (!$feof(fd)) begin
      line_num = line_num + 1;
      if ($fgets(line, fd)) begin

        // tolerate optional spaces and optional 0x prefixes
        matched = $sscanf(line, "0x%h , 0x%h", addr, value);
        if (matched != 2) matched = $sscanf(line, "0x%h,0x%h", addr, value);
        if (matched != 2) matched = $sscanf(line, "%h , %h",  addr, value);
        if (matched != 2) matched = $sscanf(line, "%h,%h",    addr, value);

        if (matched == 2) begin
          // bounds check
          while(addr!=addr2) begin
            if($fgets(line2,fd2)) begin
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
          if ((addr+3) >= MEM_BYTES) begin
            $display("FAIL @ line %0d: addr 0x%08h out of range", line_num, addr);
            $finish;
          end
          // assemble word: MSB at lowest address (matches your mem read logic)
          got_word = {dut_mem[addr+0], dut_mem[addr+1], dut_mem[addr+2], dut_mem[addr+3]};
          if (value2 !== value) begin
            $display("FAIL @ line %0d: addr=0x%08h got=0x%08h exp=0x%08h",
                     line_num, addr, value2, value);
            $finish;
          end
          else begin
             $display("Passed @ line %0d: addr=0x%08h got=0x%08h exp=0x%08h",
                     line_num, addr, value2, value);
          end
        end
        
      end
    end

    $display("PASS: all CSV memory values match DUT dump.");
    $fclose(fd);
    $fclose(fd2);
    $finish;
  end

endmodule
