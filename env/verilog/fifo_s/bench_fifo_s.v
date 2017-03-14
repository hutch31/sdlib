`timescale 1ns/1ns

module bench_fifo_s;

  reg clk_src, clk_dst, reset;

  localparam width = 8;
  localparam depth = 8;
  localparam asz = $clog2(depth);

  initial clk_src = 0;
  always #25 clk_src = ~clk_src;

  initial clk_dst = 0;
  always #20 clk_dst = ~clk_dst;

  /*AUTOWIRE*/
  // Beginning of automatic wires (for undeclared instantiated-module outputs)
  wire [width-1:0]	chk_data;		// From fifo_s of sd_fifo_s.v
  wire			chk_drdy;		// From chk of sd_seq_check.v
  wire			chk_srdy;		// From fifo_s of sd_fifo_s.v
  wire [asz:0]		chk_usage;		// From fifo_s of sd_fifo_s.v
  wire [width-1:0]	gen_data;		// From gen of sd_seq_gen.v
  wire			gen_drdy;		// From fifo_s of sd_fifo_s.v
  wire			gen_srdy;		// From gen of sd_seq_gen.v
  wire [asz:0]		gen_usage;		// From fifo_s of sd_fifo_s.v
  // End of automatics

/* sd_seq_gen AUTO_TEMPLATE
 (
 .clk (clk_src),
 .p_\(.*\)   (gen_\1[]),
 );
 */
  sd_seq_gen gen
    (/*AUTOINST*/
     // Outputs
     .p_srdy				(gen_srdy),		 // Templated
     .p_data				(gen_data[width-1:0]),	 // Templated
     // Inputs
     .clk				(clk_src),		 // Templated
     .reset				(reset),
     .p_drdy				(gen_drdy));		 // Templated

/* sd_seq_check AUTO_TEMPLATE
 (
 .clk (clk_dst),
 .c_\(.*\)   (chk_\1[]),
 );
 */
  sd_seq_check chk
    (/*AUTOINST*/
     // Outputs
     .c_drdy				(chk_drdy),		 // Templated
     // Inputs
     .clk				(clk_dst),		 // Templated
     .reset				(reset),
     .c_srdy				(chk_srdy),		 // Templated
     .c_data				(chk_data[width-1:0]));	 // Templated

/* sd_fifo_s AUTO_TEMPLATE
 (
     .c_clk                             (clk_src),
     .c_reset                           (reset),
     .p_clk                             (clk_dst),
     .p_reset                           (reset),
     .p_\(.*\)   (chk_\1[]),
     .c_\(.*\)   (gen_\1[]),
 );
 */
  sd_fifo_s #(.width(8), .depth(depth), .async(1)) fifo_s
    (/*AUTOINST*/
     // Outputs
     .c_drdy				(gen_drdy),		 // Templated
     .c_usage				(gen_usage[asz:0]),	 // Templated
     .p_srdy				(chk_srdy),		 // Templated
     .p_data				(chk_data[width-1:0]),	 // Templated
     .p_usage				(chk_usage[asz:0]),	 // Templated
     // Inputs
     .c_clk				(clk_src),		 // Templated
     .c_reset				(reset),		 // Templated
     .c_srdy				(gen_srdy),		 // Templated
     .c_data				(gen_data[width-1:0]),	 // Templated
     .p_clk				(clk_dst),		 // Templated
     .p_reset				(reset),		 // Templated
     .p_drdy				(chk_drdy));		 // Templated

  initial
    begin
      $dumpfile("fifo_s.vcd");
      $dumpvars;
      reset = 1;
      #100;
      reset = 0;

      gen.rep_count = 1000;

      // burst normal data for 20 cycles
      repeat (100) @(posedge clk_src);

      gen.srdy_pat = 8'h5A;
      repeat (20) @(posedge clk_src);

      chk.drdy_pat = 8'hA5;
      repeat (40) @(posedge clk_src);

      // check FIFO overflow
      gen.srdy_pat = 8'hFD;
      chk.drdy_pat = 8'h03;
      repeat (100) @(posedge clk_src);

      // check FIFO underflow
      gen.srdy_pat = 8'h11;
      chk.drdy_pat = 8'hEE;
      repeat (100) @(posedge clk_src);

      // Run out the remainder of the repeat count
      gen.srdy_pat = 8'hF0;
      chk.drdy_pat = 8'h0F;
      fork
        begin : runout
          while (gen.rep_count > 0) @(posedge clk_src);
        end
        begin : timeout
          repeat (10000) @(posedge clk_src);
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
