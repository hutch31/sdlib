`timescale 1ns/1ns

module bench_fifo_c;

  reg clk, reset;

  localparam width = 8;
  localparam depth = 7;
  localparam usz = $clog2(depth+1);

  initial clk = 0;
  always #10 clk = ~clk;

  /*AUTOWIRE*/
  // Beginning of automatic wires (for undeclared instantiated-module outputs)
  wire [7:0]            chk_data;               // From fifo_s of sd_fifo_c.v
  wire                  chk_drdy;               // From chk of sd_seq_check.v
  wire                  chk_srdy;               // From fifo_s of sd_fifo_c.v
  wire [width-1:0]      gen_data;               // From gen of sd_seq_gen.v
  wire                  gen_drdy;               // From fifo_s of sd_fifo_c.v
  wire                  gen_srdy;               // From gen of sd_seq_gen.v
  wire [usz-1:0]        usage;                  // From fifo_s of sd_fifo_c.v
  // End of automatics

/* sd_seq_gen AUTO_TEMPLATE
 (
 .p_\(.*\)   (gen_\1[]),
 );
 */
  sd_seq_gen gen
    (/*AUTOINST*/
     // Outputs
     .p_srdy                            (gen_srdy),              // Templated
     .p_data                            (gen_data[width-1:0]),   // Templated
     // Inputs
     .clk                               (clk),
     .reset                             (reset),
     .p_drdy                            (gen_drdy));              // Templated

/* sd_seq_check AUTO_TEMPLATE
 (
 .c_\(.*\)   (chk_\1[]),
 );
 */
  sd_seq_check #(.width(width)) chk
    (/*AUTOINST*/
     // Outputs
     .c_drdy                            (chk_drdy),              // Templated
     // Inputs
     .clk                               (clk),
     .reset                             (reset),
     .c_srdy                            (chk_srdy),              // Templated
     .c_data                            (chk_data[(width)-1:0])); // Templated

/* sd_fifo_c AUTO_TEMPLATE
 (
     .p_\(.*\)   (chk_\1[]),
     .c_\(.*\)   (gen_\1[]),
 );
 */
  sd_fifo_c #(.width(8), .depth(depth)) fifo_s
    (/*AUTOINST*/
     // Outputs
     .c_drdy                            (gen_drdy),              // Templated
     .usage                             (usage[usz-1:0]),
     .p_srdy                            (chk_srdy),              // Templated
     .p_data                            (chk_data[7:0]),         // Templated
     // Inputs
     .clk                               (clk),
     .reset                             (reset),
     .c_srdy                            (gen_srdy),              // Templated
     .c_data                            (gen_data[7:0]),         // Templated
     .p_drdy                            (chk_drdy));              // Templated

  initial
    begin
`ifdef MODEL_TECH
      $wlfdumpvars(0, bench_fifo_c);
`else
      $dumpfile("fifo_s.vcd");
      $dumpvars;
`endif
      reset = 1;
      #100;
      reset = 0;

      gen.rep_count = 9000;

      // burst normal data for 20 cycles
      repeat (20) @(posedge clk);

      gen.srdy_pat = 8'h5A;
      repeat (20) @(posedge clk);

      chk.drdy_pat = 8'hA5;
      repeat (40) @(posedge clk);

      // check FIFO overflow
      gen.srdy_pat = 8'hFD;
      chk.drdy_pat = 8'h03;
      repeat (100) @(posedge clk);

      // check FIFO underflow
      gen.srdy_pat = 8'h11;
      chk.drdy_pat = 8'hEE;
      repeat (100) @(posedge clk);

      // Run out the remainder of the repeat count
      fork
        begin : runout
          while (gen.rep_count > 0) 
            begin
              gen.srdy_pat = {$random} | (1 << ($random % 8));
              chk.drdy_pat = {$random} | (1 << ($random % 8));
              repeat (16) @(posedge clk);
            end
        end
        begin : timeout
          repeat (10000) @(posedge clk);
          disable runout;
        end
      join

      if (chk.ok_cnt >= 1000)
        $display ("----- TEST PASSED -----");
      else
        begin
          $display ("***** TEST FAILED *****");
          $display ("Ok count=%4d", chk.ok_cnt);
        end


      #5000;
      $finish;
    end

endmodule // bench_fifo_s
// Local Variables:
// verilog-library-directories:("." "../common" "../../../rtl/verilog/buffers")
// End:
