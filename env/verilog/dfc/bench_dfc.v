`timescale 1ns/1ns

module bench_dfc;

  reg clk, reset;

  localparam width = 8;
  localparam depth = 8;
  localparam asz = $clog2(depth);

  initial clk = 0;
  always #10 clk = ~clk;

  /*AUTOWIRE*/
  // Beginning of automatic wires (for undeclared instantiated-module outputs)
  wire [width-1:0]      chk_data;               // From dfca of dfc_receiver.v
  wire                  chk_drdy;               // From chk of sd_seq_check.v
  wire                  chk_srdy;               // From dfca of dfc_receiver.v
  wire [width-1:0]      gen_data;               // From gen of sd_seq_gen.v
  wire                  gen_drdy;               // From driver of dfc_sender.v
  wire                  gen_srdy;               // From gen of sd_seq_gen.v
  wire [width-1:0]      s0_data;                // From driver of dfc_sender.v
  wire                  s0_vld;                 // From driver of dfc_sender.v
  wire                  s2_fc_n;                // From dfca of dfc_receiver.v
  // End of automatics

  reg [width-1:0]       s1_data, s2_data, s3_data, s4_data;
  reg                   s1_vld, s2_vld, s3_vld, s4_vld;
  //reg                   s0_drdy, , s2_drdy, s3_drdy;
  reg                   s0_fc_n, s1_fc_n;
  wire                  s2_drdy;

/* sd_seq_gen AUTO_TEMPLATE
 (
 .p_\(.*\)   (gen_\1[]),
 );
 */
  sd_seq_gen #(.pat_dep(32)) gen
    (/*AUTOINST*/
     // Outputs
     .p_srdy                            (gen_srdy),              // Templated
     .p_data                            (gen_data[width-1:0]),   // Templated
     // Inputs
     .clk                               (clk),
     .reset                             (reset),
     .p_drdy                            (gen_drdy));              // Templated

/* dfc_sender AUTO_TEMPLATE
 (
 .c_\(.*\)   (gen_\1[]),
 .p_\(.*\)    (s0_\1[]),
 );
 */
  dfc_sender #(.width (width)) driver
    (/*AUTOINST*/
     // Outputs
     .c_drdy                            (gen_drdy),              // Templated
     .p_vld                             (s0_vld),                // Templated
     .p_data                            (s0_data[width-1:0]),    // Templated
     // Inputs
     .clk                               (clk),
     .reset                             (reset),
     .c_srdy                            (gen_srdy),              // Templated
     .c_data                            (gen_data[width-1:0]),   // Templated
     .p_fc_n                            (s0_fc_n));               // Templated

  always @(posedge clk)
    begin
      { s1_vld, s1_data } <= { s0_vld, s0_data };
      { s2_vld, s2_data } <= { s1_vld, s1_data };
      { s3_vld, s3_data } <= { s2_vld, s2_data };
      { s4_vld, s4_data } <= { s3_vld, s3_data };
      s0_fc_n  <= s1_fc_n;
      s1_fc_n  <= s2_fc_n;
    end

/* dfc_receiver AUTO_TEMPLATE
 (
 .c_\(.*\)    (s2_\1[]),
 .p_\(.*\)    (chk_\1[]),
 );
 */
  dfc_receiver #(.width(width), .depth(depth), .threshold(1)) dfca
    (/*AUTOINST*/
     // Outputs
     .c_fc_n                            (s2_fc_n),               // Templated
     .p_srdy                            (chk_srdy),              // Templated
     .p_data                            (chk_data[width-1:0]),   // Templated
     // Inputs
     .clk                               (clk),
     .reset                             (reset),
     .c_vld                             (s2_vld),                // Templated
     .c_data                            (s2_data[width-1:0]),    // Templated
     .p_drdy                            (chk_drdy));              // Templated
  

/* sd_seq_check AUTO_TEMPLATE
 (
 .c_\(.*\)   (chk_\1[]),
 );
 */
  sd_seq_check #(.pat_dep(32)) chk
    (/*AUTOINST*/
     // Outputs
     .c_drdy                            (chk_drdy),              // Templated
     // Inputs
     .clk                               (clk),
     .reset                             (reset),
     .c_srdy                            (chk_srdy),              // Templated
     .c_data                            (chk_data[width-1:0]));   // Templated

 

  initial
    begin
`ifdef MODEL_TECH
      $wlfdumpvars(0, bench_dfc);
`else
      $dumpfile("dfc.vcd");
      $dumpvars;
`endif
      reset = 1;
      #100;
      reset = 0;

      gen.rep_count = 1000;

      // burst normal data for 20 cycles
      gen.srdy_pat = 32'hFFFFFFFF;
      chk.drdy_pat = 32'hFFFFFFFF;
      repeat (40) @(posedge clk);

      // Shut off receiver and make sure fifo does not overflow
      chk.drdy_pat = 32'h0;
      repeat (depth*2) @(posedge clk);

      gen.srdy_pat = {4{8'h5A}};
      chk.drdy_pat = 32'hFFFFFFFF;
      repeat (20) @(posedge clk);

      chk.drdy_pat = {4{8'hA5}};
      repeat (40) @(posedge clk);

      // check FIFO overflow
      gen.srdy_pat = {4{8'hFD}};
      chk.drdy_pat = {4{8'h03}};
      repeat (100) @(posedge clk);

      // check FIFO underflow
      gen.srdy_pat = {4{8'h11}};
      chk.drdy_pat = {4{8'hEE}};
      repeat (100) @(posedge clk);

      // Run out the remainder of the repeat count
      gen.srdy_pat = 32'hFFFF0000;
      chk.drdy_pat = 32'h0000FFFF;
      fork
        begin : runout
          while (gen.rep_count > 0) @(posedge clk);
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
// verilog-library-directories:("." "../common" "../../../rtl/verilog/closure" "../../../rtl/verilog/buffers")
// End:
