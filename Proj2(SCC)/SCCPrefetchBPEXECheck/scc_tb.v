`timescale 1ns/1ns

module scc_tb();
    reg clk_tb = 0;
    reg rst_tb = 1;
    reg clk_en_tb = 1;
    wire halt_f_tb;
    wire [1:0] err_bits_tb;
    wire [31:0] instruction_memory_v_tb;
    wire [31:0] data_memory_in_v_tb;

    always #5 clk_tb = ~clk_tb;

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, scc_tb);   
    end

    always @(posedge clk_tb) begin
        if(halt_f_tb) begin
            $display("Apollo has landed");
            $finish;
        end
    end

 
    scc_f25_top uut(
        .clk(clk_tb),
        .rst(rst_tb),
        .clk_en(clk_en_tb),
        .halt_f(halt_f_tb),
        .err_bits(err_bits_tb),
        .instruction_memory_v(instruction_memory_v_tb),
        .data_memory_in_v(data_memory_in_v_tb)
    );


    task fail_and_stop;
    input [1023:0] msg;
    begin
      $display("[%0t] FAIL: %0s", $time, msg);
      $finish;
    end
  endtask

  task pass_and_stop;
    begin
      $display("[%0t] PASS", $time);
      $finish;
    end
  endtask

  task run_checks;
    integer i;
    reg [31:0] got, exp;
    begin
      // Check the 10 words at DATA_BASE
      for (i = 0; i < NUM_WORDS; i = i + 1) begin
        got = get_word(DATA_BASE + i*4);
        if (EXPECT_SORTED != 0)
          exp = i + 1;          // expect 1..10
        else
          exp = init_block[i];  // expect unchanged

        if (got !== exp) begin
          $display("Mismatch @ [0x%08x]: got=0x%08x exp=0x%08x",
                    DATA_BASE + i*4, got, exp);
          fail_and_stop("Data block verification failed");
        end
      end

      // Optional: ensure no error flags
      if (err_bits_tb !== 2'b00) begin
        $display("err_bits_tb nonzero: %b", err_bits_tb);
        fail_and_stop("err_bits_tb indicates error");
      end
    end
  endtask
    
    initial begin
        repeat(3)@(posedge clk_tb);
        #1 rst_tb = 0;
        repeat(5000)@(posedge clk_tb);
        $finish;

    end

endmodule
