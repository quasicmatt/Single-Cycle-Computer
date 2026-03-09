`timescale 10ms/1ms


module shift_count_tb();

  //top level inputs
  reg clk_tb;
  reg clk_en_tb;
  reg rst_tb;

  //top level outputs
  wire halt_f_tb;
  wire [1:0]  err_bits_tb;
  wire [31:0] instruction_tb;
  wire [31:0] data_memory_in_v_tb;

  //replace w/ name of module
  scc_f25_top top (
  .clk(clk_tb),
  .clk_en(clk_en_tb),
  .rst(rst_tb),
  .halt_f(halt_f_tb),
  .err_bits(err_bits_tb),
  .instruction_memory_v(instruction_tb),
  .data_memory_in_v(data_memory_in_v_tb)
	);

  integer file, i, status;
  reg [255:0] line;     //current line in scc_out.txt

  // target addresses
  reg [255:0] target_a_1, target_a_2, target_a_3, target_a_4, target_a_5, target_a_6;

  // target values
  reg [255:0] target_v_1, target_v_2, target_v_3, target_v_4, target_v_5, target_v_6;

  // actual values found in memory
  reg [255:0] value1, value2, value3, value4, value5, value6;

  //clocking
  initial begin
    clk_tb = 0;
    forever #1 clk_tb = ~clk_tb;
  end

  //inputs
  initial begin
	// name of testbench
	$dumpvars(0, shift_count_tb);

    rst_tb = 1;
    #6
    rst_tb = 0;
    #6
    #1500;

    //defining target address and expected memory
    target_a_1 = "0x00000880";
    target_a_2 = "0x00000884";
    target_a_3 = "0x00000888";
    target_a_4 = "0x0000088c";
    target_a_5 = "0x00000890";
    target_a_6 = "0x00000894";
    
    target_v_1 = "0x00000010";
    target_v_2 = "0x00000010";
    target_v_3 = "0x00100010";
    target_v_4 = "0x0f0f0f0f";
    target_v_5 = "0x00000100";
    target_v_6 = "0x00000100";

    //iterating through output file
    file = $fopen("scc_out.txt", "r");
    if (file == 0) begin
      $display("ERROR: FILE NOT FOUND");
    end else begin
      for (i = 1; i < 16386; i = i+1) begin
        status = $fgets(line, file);  //look at and store one line
        if (line[175:96] == target_a_1) begin
          value1 = line[87:8]; //storing value @ R2Data
        end else if (line[175:96] == target_a_2) begin
          value2 = line[87:8];
        end else if (line[175:96] == target_a_3) begin
          value3 = line[87:8];
        end else if (line[175:96] == target_a_4) begin
          value4 = line[87:8];
        end else if (line[175:96] == target_a_5) begin
          value5 = line[87:8];
        end else if (line[175:96] == target_a_6) begin
          value6 = line[87:8];
        end 
      end
    end

    $display("shift_count (Group 6) testcase results:");
	$display("Target Address: %s", target_a_1[79:0]);
    $display("Expected Value: %s", target_v_1[79:0]);
    $display("Actual Value: %s", value1[79:0]);
    $display("Target Address: %s", target_a_2[79:0]);
    $display("Expected Value: %s", target_v_2[79:0]);
    $display("Actual Value: %s", value2[79:0]);
    $display("Target Address: %s", target_a_3[79:0]);
    $display("Expected Value: %s", target_v_3[79:0]);
    $display("Actual Value: %s", value3[79:0]);
    $display("Target Address: %s", target_a_4[79:0]);
    $display("Expected Value: %s", target_v_4[79:0]);
    $display("Actual Value: %s", value4[79:0]);
    $display("Target Address: %s", target_a_5[79:0]);
    $display("Expected Value: %s", target_v_5[79:0]);
    $display("Actual Value: %s", value5[79:0]);
    $display("Target Address: %s", target_a_6[79:0]);
    $display("Expected Value: %s", target_v_6[79:0]);
    $display("Actual Value: %s", value6[79:0]);
    if (target_v_1[79:0] == value1[79:0] && target_v_2[79:0] == value2[79:0] && target_v_3[79:0] == value3[79:0]
    && target_v_4[79:0] == value4[79:0] && target_v_5[79:0] == value5[79:0] && target_v_6[79:0] == value6[79:0]) begin
      $display("Test Passed!");
    end else begin
      $display("ggs");
    end
    
    $finish;
  end
endmodule
