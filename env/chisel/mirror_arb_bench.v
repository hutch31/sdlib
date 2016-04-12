`timescale 1ns/1ns

module bench;

  reg clk, reset;

  localparam width = 8;
  localparam depth = 7;
  localparam usz = $clog2(depth+1);

  initial clk = 0;
  always #10 clk = ~clk;

  /*AUTOWIRE*/
  // Beginning of automatic wires (for undeclared instantiated-module outputs)
  wire [7:0]		chk0_data;		// From dut of WrapInput.v
  wire			chk0_drdy;		// From chk0 of sd_seq_check.v
  wire			chk0_srdy;		// From dut of WrapInput.v
  wire [7:0]		chk1_data;		// From dut of WrapInput.v
  wire			chk1_drdy;		// From chk1 of sd_seq_check.v
  wire			chk1_srdy;		// From dut of WrapInput.v
  wire [7:0]		chk2_data;		// From dut of WrapInput.v
  wire			chk2_drdy;		// From chk2 of sd_seq_check.v
  wire			chk2_srdy;		// From dut of WrapInput.v
  wire [7:0]		chk3_data;		// From dut of WrapInput.v
  wire			chk3_drdy;		// From chk3 of sd_seq_check.v
  wire			chk3_srdy;		// From dut of WrapInput.v
  wire [width-1:0]	gen0_data;		// From gen0 of sd_seq_gen.v
  wire			gen0_drdy;		// From dut of WrapInput.v
  wire			gen0_srdy;		// From gen0 of sd_seq_gen.v
  wire [width-1:0]	gen1_data;		// From gen1 of sd_seq_gen.v
  wire			gen1_drdy;		// From dut of WrapInput.v
  wire			gen1_srdy;		// From gen1 of sd_seq_gen.v
  wire [width-1:0]	gen2_data;		// From gen2 of sd_seq_gen.v
  wire			gen2_drdy;		// From dut of WrapInput.v
  wire			gen2_srdy;		// From gen2 of sd_seq_gen.v
  wire [width-1:0]	gen3_data;		// From gen3 of sd_seq_gen.v
  wire			gen3_drdy;		// From dut of WrapInput.v
  wire			gen3_srdy;		// From gen3 of sd_seq_gen.v
  // End of automatics

/* sd_seq_gen AUTO_TEMPLATE
 (
 .p_\(.*\)   (gen@_\1[]),
 );
 */
  sd_seq_gen #(.width(width)) gen0
    (/*AUTOINST*/
     // Outputs
     .p_srdy				(gen0_srdy),		 // Templated
     .p_data				(gen0_data[width-1:0]),	 // Templated
     // Inputs
     .clk				(clk),
     .reset				(reset),
     .p_drdy				(gen0_drdy));		 // Templated

  sd_seq_gen #(.width(width)) gen1
    (/*AUTOINST*/
     // Outputs
     .p_srdy				(gen1_srdy),		 // Templated
     .p_data				(gen1_data[width-1:0]),	 // Templated
     // Inputs
     .clk				(clk),
     .reset				(reset),
     .p_drdy				(gen1_drdy));		 // Templated

  sd_seq_gen #(.width(width)) gen2
    (/*AUTOINST*/
     // Outputs
     .p_srdy				(gen2_srdy),		 // Templated
     .p_data				(gen2_data[width-1:0]),	 // Templated
     // Inputs
     .clk				(clk),
     .reset				(reset),
     .p_drdy				(gen2_drdy));		 // Templated

  sd_seq_gen #(.width(width)) gen3
    (/*AUTOINST*/
     // Outputs
     .p_srdy				(gen3_srdy),		 // Templated
     .p_data				(gen3_data[width-1:0]),	 // Templated
     // Inputs
     .clk				(clk),
     .reset				(reset),
     .p_drdy				(gen3_drdy));		 // Templated

/* sd_seq_check AUTO_TEMPLATE
 (
 .c_\(.*\)   (chk@_\1[]),
 );
 */
  sd_seq_check #(.width(width)) chk0
    (/*AUTOINST*/
     // Outputs
     .c_drdy				(chk0_drdy),		 // Templated
     // Inputs
     .clk				(clk),
     .reset				(reset),
     .c_srdy				(chk0_srdy),		 // Templated
     .c_data				(chk0_data[width-1:0]));	 // Templated

  sd_seq_check #(.width(width)) chk1
    (/*AUTOINST*/
     // Outputs
     .c_drdy				(chk1_drdy),		 // Templated
     // Inputs
     .clk				(clk),
     .reset				(reset),
     .c_srdy				(chk1_srdy),		 // Templated
     .c_data				(chk1_data[width-1:0]));	 // Templated

  sd_seq_check #(.width(width)) chk2
    (/*AUTOINST*/
     // Outputs
     .c_drdy				(chk2_drdy),		 // Templated
     // Inputs
     .clk				(clk),
     .reset				(reset),
     .c_srdy				(chk2_srdy),		 // Templated
     .c_data				(chk2_data[width-1:0]));	 // Templated

  sd_seq_check #(.width(width)) chk3
    (/*AUTOINST*/
     // Outputs
     .c_drdy				(chk3_drdy),		 // Templated
     // Inputs
     .clk				(clk),
     .reset				(reset),
     .c_srdy				(chk3_srdy),		 // Templated
     .c_data				(chk3_data[width-1:0]));	 // Templated

/* WrapInput AUTO_TEMPLATE
 (
  .io_p_\([0-9]\)_ready (chk\1_drdy),
  .io_p_\([0-9]\)_valid (chk\1_srdy),
  .io_p_\([0-9]\)_bits  (chk\1_data[]),
  .io_c_\([0-9]\)_valid (gen\1_srdy),
  .io_c_\([0-9]\)_ready (gen\1_drdy),
  .io_c_\([0-9]\)_bits  (gen\1_data[]),
 );
 */
  WrapInput  dut
    (/*AUTOINST*/
     // Outputs
     .io_c_3_ready			(gen3_drdy),		 // Templated
     .io_c_2_ready			(gen2_drdy),		 // Templated
     .io_c_1_ready			(gen1_drdy),		 // Templated
     .io_c_0_ready			(gen0_drdy),		 // Templated
     .io_p_3_valid			(chk3_srdy),		 // Templated
     .io_p_3_bits			(chk3_data[7:0]),	 // Templated
     .io_p_2_valid			(chk2_srdy),		 // Templated
     .io_p_2_bits			(chk2_data[7:0]),	 // Templated
     .io_p_1_valid			(chk1_srdy),		 // Templated
     .io_p_1_bits			(chk1_data[7:0]),	 // Templated
     .io_p_0_valid			(chk0_srdy),		 // Templated
     .io_p_0_bits			(chk0_data[7:0]),	 // Templated
     // Inputs
     .clk				(clk),
     .reset				(reset),
     .io_c_3_valid			(gen3_srdy),		 // Templated
     .io_c_3_bits			(gen3_data[7:0]),	 // Templated
     .io_c_2_valid			(gen2_srdy),		 // Templated
     .io_c_2_bits			(gen2_data[7:0]),	 // Templated
     .io_c_1_valid			(gen1_srdy),		 // Templated
     .io_c_1_bits			(gen1_data[7:0]),	 // Templated
     .io_c_0_valid			(gen0_srdy),		 // Templated
     .io_c_0_bits			(gen0_data[7:0]),	 // Templated
     .io_p_3_ready			(chk3_drdy),		 // Templated
     .io_p_2_ready			(chk2_drdy),		 // Templated
     .io_p_1_ready			(chk1_drdy),		 // Templated
     .io_p_0_ready			(chk0_drdy));		 // Templated

  initial
    begin
`ifdef MODEL_TECH
      $wlfdumpvars(0, bench_fifo_c);
`else
      $dumpfile("bench.vcd");
      $dumpvars;
`endif
      reset = 1;
      #100;
      reset = 0;

      gen0.rep_count = 100;
      gen1.rep_count = 100;
      gen2.rep_count = 100;
      gen3.rep_count = 100;

      repeat (50+4*100)
        @(posedge clk);

      if (chk0.ok_cnt >= 100)
        $display ("----- TEST PASSED -----");
      else
        begin
          $display ("***** TEST FAILED *****");
          $display ("Ok count=%4d", chk0.ok_cnt);
        end


      #5000;
      $finish;
    end

endmodule // bench_fifo_s
// Local Variables:
// verilog-library-directories:("." "../verilog/common" "../../rtl/chisel" )
// End:
