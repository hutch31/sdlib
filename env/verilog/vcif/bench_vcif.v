`timescale 1ns/1ns
`define SDLIB_CLOCKING posedge clk
`define SDLIB_DELAY

module bench_fifo_s;

  reg clk, reset;

  localparam width = 8;
  localparam depth = 8;
  localparam asz   = 3;

  initial clk = 0;
  always #10 clk = ~clk;

  /*AUTOWIRE*/
  // Beginning of automatic wires (for undeclared instantiated-module outputs)
  wire [width-1:0]      chk_data;               // From mem2p of behave2p_mem.v
  wire                  chk_drdy;               // From chk of sd_seq_check.v
  wire                  chk_srdy;               // From tail of sd_fifo_tail_s.v
  wire [(width)-1:0]    gen_data;               // From gen of sd_seq_gen.v
  wire                  gen_drdy;               // From sd2vc of sd2vc.v
  wire                  gen_srdy;               // From gen of sd_seq_gen.v
  wire [asz-1:0]        rd_addr;                // From tail of sd_fifo_tail_s.v
  wire                  rd_en;                  // From tail of sd_fifo_tail_s.v
  wire [asz:0]          rdptr_tail;             // From tail of sd_fifo_tail_s.v
  wire [(asz):0]        usage;                  // From vchead of vc_fifo_head_s.v
  wire [(asz)-1:0]      wr_addr;                // From vchead of vc_fifo_head_s.v
  wire [(width)-1:0]    wr_data;                // From vchead of vc_fifo_head_s.v
  wire                  wr_en;                  // From vchead of vc_fifo_head_s.v
  wire [(asz):0]        wrptr_head;             // From vchead of vc_fifo_head_s.v
  wire                  x_cr;                   // From vchead of vc_fifo_head_s.v
  wire [(width)-1:0]    x_data;                 // From sd2vc of sd2vc.v
  wire                  x_vld;                  // From sd2vc of sd2vc.v
  // End of automatics

/* sd_seq_gen AUTO_TEMPLATE
 (
 .p_\(.*\)   (gen_\1[]),
 );
 */
  sd_seq_gen #(.width(width))gen
    (/*AUTOINST*/
     // Outputs
     .p_srdy                            (gen_srdy),              // Templated
     .p_data                            (gen_data[(width)-1:0]), // Templated
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

/* sd2vc AUTO_TEMPLATE
 (
 .c_\(.*\)   (gen_\1[]),
     .p_vld                             (x_vld),
     .p_cr                              (x_cr),
     .p_data                            (x_data[]),
 );
 */
  sd2vc #(.width(width), .cc_sz(5), .reginp(1)) sd2vc
    (/*AUTOINST*/
     // Outputs
     .c_drdy                            (gen_drdy),              // Templated
     .p_vld                             (x_vld),                 // Templated
     .p_data                            (x_data[(width)-1:0]),   // Templated
     // Inputs
     .clk                               (clk),
     .reset                             (reset),
     .c_srdy                            (gen_srdy),              // Templated
     .c_data                            (gen_data[(width)-1:0]), // Templated
     .p_cr                              (x_cr));                  // Templated

  /* vc_fifo_head_s AUTO_TEMPLATE
   (
     .c_vld                             (x_vld),
     .c_cr                              (x_cr),
     .c_data                            (x_data[]),
   );
   */
  vc_fifo_head_s #(
                   // Parameters
                   .depth               (depth),
                   .width               (width),
                   .reginp              (1))
  vchead
    (/*AUTOINST*/
     // Outputs
     .c_cr                              (x_cr),                  // Templated
     .wrptr_head                        (wrptr_head[(asz):0]),
     .wr_addr                           (wr_addr[(asz)-1:0]),
     .wr_en                             (wr_en),
     .wr_data                           (wr_data[(width)-1:0]),
     .usage                             (usage[(asz):0]),
     // Inputs
     .clk                               (clk),
     .reset                             (reset),
     .c_vld                             (x_vld),                 // Templated
     .c_data                            (x_data[(width)-1:0]),   // Templated
     .rdptr_tail                        (rdptr_tail[(asz):0]));
  
/* behave2p_mem AUTO_TEMPLATE
    (.d_out (chk_data[]),
     .wr_en (wr_en),
     .rd_en (rd_en),
     .wr_clk (clk),
     .wr_addr (wr_addr),
     .rd_clk  (clk),
     .rd_addr (rd_addr),
     .d_in    (wr_data[]));
 */
  behave2p_mem #(width, depth) mem2p
    (/*AUTOINST*/
     // Outputs
     .d_out                             (chk_data[width-1:0]),   // Templated
     // Inputs
     .wr_en                             (wr_en),                 // Templated
     .rd_en                             (rd_en),                 // Templated
     .wr_clk                            (clk),                   // Templated
     .rd_clk                            (clk),                   // Templated
     .d_in                              (wr_data[width-1:0]),    // Templated
     .rd_addr                           (rd_addr),               // Templated
     .wr_addr                           (wr_addr));               // Templated
  
/* sd_fifo_tail_s AUTO_TEMPLATE
 (
     .c_clk                             (clk),
     .c_reset                           (reset),
     .p_clk                             (clk),
     .p_reset                           (reset),
     .p_\(.*\)   (chk_\1[]),
     .c_\(.*\)   (gen_\1[]),
 );
 */
  sd_fifo_tail_s #(.depth(depth)) tail
    (/*AUTOINST*/
     // Outputs
     .rdptr_tail                        (rdptr_tail[asz:0]),
     .rd_en                             (rd_en),
     .rd_addr                           (rd_addr[asz-1:0]),
     .p_srdy                            (chk_srdy),              // Templated
     // Inputs
     .clk                               (clk),
     .reset                             (reset),
     .wrptr_head                        (wrptr_head[asz:0]),
     .p_drdy                            (chk_drdy));              // Templated
  
  initial
    begin
      $dumpfile("fifo_s.vcd");
      $dumpvars;
      reset = 1;
      #100;
      reset = 0;

      repeat (16) @(posedge clk);
      
      gen.rep_count = 1000;

      // burst normal data for 20 cycles
      repeat (20) @(posedge clk);

      gen.srdy_pat = 8'h5A;
      repeat (20) @(posedge clk);

      gen.srdy_pat = 8'h0;
      repeat (20) @(posedge clk);

      gen.srdy_pat = 8'hFF;
      chk.drdy_pat = 8'hA5;
      repeat (40) @(posedge clk);

      // check FIFO overflow
      gen.srdy_pat = 8'hFD;
      repeat (100) @(posedge clk);

      // check FIFO underflow
      gen.srdy_pat = 8'h11;
      repeat (100) @(posedge clk);

      #50000;
      $finish;
    end

endmodule // bench_fifo_s
// Local Variables:
// verilog-library-directories:("." "../common" "../../../rtl/verilog/buffers" "../../../rtl/verilog/utility" "../../../rtl/verilog/memory")
// End:
