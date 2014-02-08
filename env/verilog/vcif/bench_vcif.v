`timescale 1ns/1ns
`define SDLIB_CLOCKING posedge clk
`define SDLIB_DELAY

`define TEST_STANDALONE

module bench_fifo_s;

  reg clk, reset, reset1;

  localparam width = 8;
  localparam depth = 6;
  localparam asz   = $clog2(depth);
  localparam usz = $clog2(depth+1);

  initial clk = 0;
  always #10 clk = ~clk;

  /*AUTOWIRE*/
  // Beginning of automatic wires (for undeclared instantiated-module outputs)
  wire [width-1:0]	chk_data;		// From rxfifo of sd_fifo_c.v
  wire			chk_drdy;		// From chk of sd_seq_check.v
  wire			chk_srdy;		// From rxfifo of sd_fifo_c.v
  wire [width-1:0]	gen_data;		// From gen of sd_seq_gen.v
  wire			gen_drdy;		// From sd2vc of sd2vc.v
  wire			gen_srdy;		// From gen of sd_seq_gen.v
  wire [width-1:0]	vf_data;		// From i_vc2sd of vc2sd.v
  wire			vf_drdy;		// From rxfifo of sd_fifo_c.v
  wire			vf_srdy;		// From i_vc2sd of vc2sd.v
  wire [usz-1:0]	vf_usage;		// From rxfifo of sd_fifo_c.v
  wire			x_cr;			// From i_vc2sd of vc2sd.v
  wire [width-1:0]	x_data;			// From sd2vc of sd2vc.v
  wire			x_vld;			// From sd2vc of sd2vc.v
  // End of automatics

/* sd_seq_gen AUTO_TEMPLATE
 (
 .p_\(.*\)   (gen_\1[]),
 );
 */
  sd_seq_gen #(.width(width))gen
    (/*AUTOINST*/
     // Outputs
     .p_srdy				(gen_srdy),		 // Templated
     .p_data				(gen_data[width-1:0]),	 // Templated
     // Inputs
     .clk				(clk),
     .reset				(reset),
     .p_drdy				(gen_drdy));		 // Templated

/* sd_seq_check AUTO_TEMPLATE
 (
 .c_\(.*\)   (chk_\1[]),
 );
 */
  sd_seq_check #(.width(width)) chk
    (/*AUTOINST*/
     // Outputs
     .c_drdy				(chk_drdy),		 // Templated
     // Inputs
     .clk				(clk),
     .reset				(reset),
     .c_srdy				(chk_srdy),		 // Templated
     .c_data				(chk_data[width-1:0]));	 // Templated

/* sd2vc AUTO_TEMPLATE
 (
 .c_\(.*\)   (gen_\1[]),
     .p_vld                             (x_vld),
     .p_cr                              (x_cr),
     .p_data                            (x_data[]),
 .reset (reset1),
 );
 */
  sd2vc #(.width(width), .cc_sz(5), 
	  .reginp(0), .wakeup_pattern (8'hF5)) 
  sd2vc
    (/*AUTOINST*/
     // Outputs
     .c_drdy				(gen_drdy),		 // Templated
     .p_vld				(x_vld),		 // Templated
     .p_data				(x_data[width-1:0]),	 // Templated
     // Inputs
     .clk				(clk),
     .reset				(reset1),		 // Templated
     .c_srdy				(gen_srdy),		 // Templated
     .c_data				(gen_data[width-1:0]),	 // Templated
     .p_cr				(x_cr));			 // Templated

  /* vc2sd AUTO_TEMPLATE
   (
     .c_vld                             (x_vld),
     .c_cr                              (x_cr),
     .c_data                            (x_data[]),
     .p_\(.*\)   (vf_\1[]),
   );
   */
  vc2sd #(
          .reginp                       (0),
          .depth                        (depth),
          .width                        (width),
	  .wakeup_pattern (8'hF5))
  i_vc2sd
    (/*AUTOINST*/
     // Outputs
     .c_cr				(x_cr),			 // Templated
     .p_srdy				(vf_srdy),		 // Templated
     .p_data				(vf_data[width-1:0]),	 // Templated
     // Inputs
     .clk				(clk),
     .reset				(reset),
     .c_vld				(x_vld),		 // Templated
     .c_data				(x_data[width-1:0]),	 // Templated
     .p_usage				(vf_usage[usz-1:0]),	 // Templated
     .p_drdy				(vf_drdy));		 // Templated

  /* sd_fifo_c AUTO_TEMPLATE
   (
   .usage (vf_usage[usz-1:0]),
   .c_\(.*\)     (vf_\1[]),
     .p_\(.*\)   (chk_\1[]),
   );
   */
  sd_fifo_c #(.width(width), .depth(depth))
  rxfifo
    (/*AUTOINST*/
     // Outputs
     .c_drdy				(vf_drdy),		 // Templated
     .usage				(vf_usage[usz-1:0]),	 // Templated
     .p_srdy				(chk_srdy),		 // Templated
     .p_data				(chk_data[width-1:0]),	 // Templated
     // Inputs
     .clk				(clk),
     .reset				(reset),
     .c_srdy				(vf_srdy),		 // Templated
     .c_data				(vf_data[width-1:0]),	 // Templated
     .p_drdy				(chk_drdy));		 // Templated
  
  initial
    begin
      $dumpfile("fifo_s.vcd");
      $dumpvars;
      reset = 1;
      reset1 = 1;
      #100;
      reset = 0;
      #200;
      reset1 = 0;

      repeat (64) @(posedge clk);
      
      gen.rep_count = 1000;

      // burst normal data for 40 cycles
      repeat (40) @(posedge clk);

      gen.srdy_pat = 8'h5A;
      repeat (20) @(posedge clk);

      gen.srdy_pat = 8'h0;
      repeat (20) @(posedge clk);

      // shutoff test
      gen.srdy_pat = 8'hFF;
      chk.drdy_pat = 8'h00;
      repeat (40) @(posedge clk);

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
