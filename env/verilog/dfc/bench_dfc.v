`timescale 1ns/1ns

module bench_dfc;

  reg clk, reset;

  localparam width = 8;
  localparam asz = $clog2(depth);

  parameter valid_delay = 6;
  parameter fc_delay = 8;
  parameter threshold = 3;
  localparam depth = (valid_delay+fc_delay+threshold);

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
  wire                  overflow;               // From dfca of dfc_receiver.v
  // End of automatics

  logic [valid_delay-1:0][width-1:0] s_data;
  logic [valid_delay-1:0]            s_vld;
  //reg                   s1_vld, s2_vld, s3_vld, s4_vld;
  //reg                   s0_drdy, , s2_drdy, s3_drdy;
  //reg                   s0_fc_n, s1_fc_n;
  logic [fc_delay-1:0]               s_fc_n;
  reg                   failed;

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
 .p_\(.*\)    (s_\1[0]),
 );
 */
  dfc_sender #(.width (width)) driver
    (/*AUTOINST*/
     // Outputs
     .c_drdy                            (gen_drdy),              // Templated
     .p_vld                             (s_vld[0]),              // Templated
     .p_data                            (s_data[0]),             // Templated
     // Inputs
     .clk                               (clk),
     .reset                             (reset),
     .c_srdy                            (gen_srdy),              // Templated
     .c_data                            (gen_data[width-1:0]),   // Templated
     .p_fc_n                            (s_fc_n[0]));             // Templated

  genvar                vd, fd;
  
  generate for (vd=1; vd<valid_delay; vd++)
    begin : valid_loop
      always @(posedge clk)
        begin
          s_vld[vd] <= s_vld[vd-1];
          s_data[vd] <= s_data[vd-1];
        end
    end
  endgenerate

  generate for (fd=0; fd<(fc_delay-1); fd++)
    begin : flow_lop
      always @(posedge clk)
        begin
          s_fc_n[fd] <= s_fc_n[fd+1];
        end
    end
  endgenerate
  
/* dfc_receiver AUTO_TEMPLATE
 (
 .c_fc_n      (s_fc_n[fc_delay-1]),
 .c_\(.*\)    (s_\1[valid_delay-1]),
 .p_\(.*\)    (chk_\1[]),
 );
 */
  dfc_receiver #(.width(width), .depth(depth), .threshold(threshold)) dfca
    (/*AUTOINST*/
     // Outputs
     .c_fc_n                            (s_fc_n[fc_delay-1]),    // Templated
     .p_srdy                            (chk_srdy),              // Templated
     .p_data                            (chk_data[width-1:0]),   // Templated
     .overflow                          (overflow),
     // Inputs
     .clk                               (clk),
     .reset                             (reset),
     .c_vld                             (s_vld[valid_delay-1]),  // Templated
     .c_data                            (s_data[valid_delay-1]), // Templated
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
      failed = 0;
      #100;
      reset = 0;

      gen.rep_count = 1000;

      // burst normal data for 20 cycles
      gen.srdy_pat = 32'hFFFFFFFF;
      chk.drdy_pat = 32'hFFFFFFFF;
      #200;
      
      repeat (100) 
        begin
          @(posedge clk);
          if ((gen_srdy && (gen_drdy !== 1'b1)) && !failed)
            begin
              $display ("%t: ERROR: Flow control asserted",$time);
              failed = 1;
            end
        end

      // Shut off receiver and make sure fifo does not overflow
      $display ("%t: Shutting off receiver",$time);
      chk.drdy_pat = 32'h0;
      repeat (40) @(posedge clk);
      $display ("%t: Enabling receiver",$time);

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

      if ((chk.ok_cnt >= 1000) && !failed)
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
