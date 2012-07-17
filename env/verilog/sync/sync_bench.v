`timescale 1ns/1ns

module sync_bench;

  parameter width = 16;
  
  wire a_clk; 
  reg a_reset;
  wire b_clk; 
  reg b_reset;
  reg fast_clk, slow_clk;

  reg clk_mode;

  assign a_clk = (clk_mode) ? fast_clk : slow_clk;
  //assign b_clk = (clk_mode) ? slow_clk : fast_clk;
  assign b_clk = a_clk;
  
  wire [width-1:0]      a_data;

  wire                  a_srdy, a_drdy;
  wire                  b_srdy, b_drdy;
  /*AUTOWIRE*/
  // Beginning of automatic wires (for undeclared instantiated-module outputs)
  wire [15:0]           b_data;                 // From iosync_b of sd_iosync_p.v
  wire                  s_ack;                  // From iosync_b of sd_iosync_p.v
  wire [15:0]           s_data;                 // From iosync_a of sd_iosync_c.v
  wire                  s_req;                  // From iosync_a of sd_iosync_c.v
  // End of automatics

  initial
    begin
`ifdef VCS
      $vcdpluson;
`else
      $dumpfile ("sync.vcd");
      $dumpvars;
`endif
      
      fast_clk = 0;
      slow_clk = 0;
      a_reset = 1;
      b_reset = 1;
      clk_mode = 0;
      #200;
      a_reset = 0;
      b_reset = 0;
      #200;

      repeat (2)
        begin
          seq_gen.srdy_pat = 8'hFF;
          seq_chk.drdy_pat = 8'hFF;
          
          seq_gen.send (25);

          seq_gen.srdy_pat = 8'h01;

          seq_gen.send (25);

          seq_gen.srdy_pat = 8'hFF;
          seq_chk.drdy_pat = 8'h01;

          seq_gen.send (25);

          seq_gen.srdy_pat = 8'h01;
          
          seq_gen.send (25);

          clk_mode = ~clk_mode;
        end
      
      
      #2000;

      if (seq_chk.last_seq == 200)
        $display ("TEST PASSED");
      else
        $display ("TEST FAILED");
        
      $finish;
    end // initial begin

  initial
    begin
      #250000; // timeout value

      $display ("TEST FAILED");
      $finish;
    end

  always fast_clk = #5 ~fast_clk;
  always slow_clk = #17 ~slow_clk;
  
  sd_seq_gen #(.width(width)) seq_gen
    (
     .clk                               (a_clk),
     .reset                             (a_reset),
     .p_srdy                            (a_srdy),
     .p_data                            (a_data),
     // Inputs
     .p_drdy                            (a_drdy));
  
/* sd_iosync_c AUTO_TEMPLATE
 (
     .p_\(.*\)   (x_\1[]),
     .c_\(.*\)   (a_\1[]),
 );
 */
  sd_iosync_c #(.width(16)) iosync_a
    (
     .clk                               (a_clk),
     .reset                             (a_reset),
     /*AUTOINST*/
     // Outputs
     .c_drdy                            (a_drdy),                // Templated
     .s_req                             (s_req),
     .s_data                            (s_data[15:0]),
     // Inputs
     .c_srdy                            (a_srdy),                // Templated
     .c_data                            (a_data[15:0]),          // Templated
     .s_ack                             (s_ack));
  
/* sd_iosync_p AUTO_TEMPLATE
 (
     .p_\(.*\)   (b_\1[]),
     .c_\(.*\)   (x_\1[]),
 );
 */
  sd_iosync_p #(.width(16)) iosync_b
    (
     .clk                               (b_clk),
     .reset                             (b_reset),
     /*AUTOINST*/
     // Outputs
     .s_ack                             (s_ack),
     .p_srdy                            (b_srdy),                // Templated
     .p_data                            (b_data[15:0]),          // Templated
     // Inputs
     .s_req                             (s_req),
     .s_data                            (s_data[15:0]),
     .p_drdy                            (b_drdy));                // Templated

  sd_seq_check #(.width(width)) seq_chk
    (
     // Outputs
     .c_drdy                            (b_drdy),
     // Inputs
     .clk                               (b_clk),
     .reset                             (b_reset),
     .c_srdy                            (b_srdy),
     .c_data                            (b_data));
  
endmodule // sync_bench
// Local Variables:
// verilog-library-directories:("." "../../../rtl/verilog/closure" "../../../rtl/verilog/utility" "../common")
// End:


