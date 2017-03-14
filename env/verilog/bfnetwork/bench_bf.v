`timescale 1ns/1ns

module bench_bf;

  reg clk, reset;

  localparam width = 16;
  localparam abits = 3;

  wire [7:0] gen_srdy;
  wire [7:0] gen_drdy;
  wire [7:0][width-1:0] gen_data;
  wire [7:0] chk_srdy;
  wire [7:0] chk_drdy;
  wire [7:0][width-1:0] chk_data;
  wire [7:0][abits-1:0] chk_addr;
  reg [7:0][abits-1:0] dest_matrix;
  integer i;
  /*AUTOWIRE*/

  initial clk = 0;
  always #10 clk = ~clk;


/* sd_seq_gen AUTO_TEMPLATE
 (
 .p_\(.*\)   (gen_\1[@]),
 );
 */
  sd_seq_gen #(.width(width)) gen0
    (/*AUTOINST*/
     // Outputs
     .p_srdy				(gen_srdy[0]),		 // Templated
     .p_data				(gen_data[0]),		 // Templated
     // Inputs
     .clk				(clk),
     .reset				(reset),
     .p_drdy				(gen_drdy[0]));		 // Templated

  sd_seq_gen #(.width(width)) gen1
   (/*AUTOINST*/
    // Outputs
    .p_srdy				(gen_srdy[1]),		 // Templated
    .p_data				(gen_data[1]),		 // Templated
    // Inputs
    .clk				(clk),
    .reset				(reset),
    .p_drdy				(gen_drdy[1]));		 // Templated

  sd_seq_gen #(.width(width)) gen2
   (/*AUTOINST*/
    // Outputs
    .p_srdy				(gen_srdy[2]),		 // Templated
    .p_data				(gen_data[2]),		 // Templated
    // Inputs
    .clk				(clk),
    .reset				(reset),
    .p_drdy				(gen_drdy[2]));		 // Templated

  sd_seq_gen #(.width(width)) gen3
   (/*AUTOINST*/
    // Outputs
    .p_srdy				(gen_srdy[3]),		 // Templated
    .p_data				(gen_data[3]),		 // Templated
    // Inputs
    .clk				(clk),
    .reset				(reset),
    .p_drdy				(gen_drdy[3]));		 // Templated

  sd_seq_gen #(.width(width)) gen4
   (/*AUTOINST*/
    // Outputs
    .p_srdy				(gen_srdy[4]),		 // Templated
    .p_data				(gen_data[4]),		 // Templated
    // Inputs
    .clk				(clk),
    .reset				(reset),
    .p_drdy				(gen_drdy[4]));		 // Templated

  sd_seq_gen #(.width(width)) gen5
   (/*AUTOINST*/
    // Outputs
    .p_srdy				(gen_srdy[5]),		 // Templated
    .p_data				(gen_data[5]),		 // Templated
    // Inputs
    .clk				(clk),
    .reset				(reset),
    .p_drdy				(gen_drdy[5]));		 // Templated

  sd_seq_gen #(.width(width)) gen6
   (/*AUTOINST*/
    // Outputs
    .p_srdy				(gen_srdy[6]),		 // Templated
    .p_data				(gen_data[6]),		 // Templated
    // Inputs
    .clk				(clk),
    .reset				(reset),
    .p_drdy				(gen_drdy[6]));		 // Templated

  sd_seq_gen #(.width(width)) gen7
   (/*AUTOINST*/
    // Outputs
    .p_srdy				(gen_srdy[7]),		 // Templated
    .p_data				(gen_data[7]),		 // Templated
    // Inputs
    .clk				(clk),
    .reset				(reset),
    .p_drdy				(gen_drdy[7]));		 // Templated

/* bf_seq_check AUTO_TEMPLATE
 (
 .c_\(.*\)   (chk_\1[@]),
 );
 */
  bf_seq_check #(.width(width)) chk0
    (/*AUTOINST*/
     // Outputs
     .c_drdy				(chk_drdy[0]),		 // Templated
     // Inputs
     .clk				(clk),
     .reset				(reset),
     .c_srdy				(chk_srdy[0]),		 // Templated
     .c_addr				(chk_addr[0]),		 // Templated
     .c_data				(chk_data[0]));		 // Templated

  bf_seq_check #(.width(width)) chk1
    (/*AUTOINST*/
     // Outputs
     .c_drdy				(chk_drdy[1]),		 // Templated
     // Inputs
     .clk				(clk),
     .reset				(reset),
     .c_srdy				(chk_srdy[1]),		 // Templated
     .c_addr				(chk_addr[1]),		 // Templated
     .c_data				(chk_data[1]));		 // Templated

  bf_seq_check #(.width(width)) chk2
    (/*AUTOINST*/
     // Outputs
     .c_drdy				(chk_drdy[2]),		 // Templated
     // Inputs
     .clk				(clk),
     .reset				(reset),
     .c_srdy				(chk_srdy[2]),		 // Templated
     .c_addr				(chk_addr[2]),		 // Templated
     .c_data				(chk_data[2]));		 // Templated

  bf_seq_check #(.width(width)) chk3
    (/*AUTOINST*/
     // Outputs
     .c_drdy				(chk_drdy[3]),		 // Templated
     // Inputs
     .clk				(clk),
     .reset				(reset),
     .c_srdy				(chk_srdy[3]),		 // Templated
     .c_addr				(chk_addr[3]),		 // Templated
     .c_data				(chk_data[3]));		 // Templated

  bf_seq_check #(.width(width)) chk4
    (/*AUTOINST*/
     // Outputs
     .c_drdy				(chk_drdy[4]),		 // Templated
     // Inputs
     .clk				(clk),
     .reset				(reset),
     .c_srdy				(chk_srdy[4]),		 // Templated
     .c_addr				(chk_addr[4]),		 // Templated
     .c_data				(chk_data[4]));		 // Templated

  bf_seq_check #(.width(width)) chk5
    (/*AUTOINST*/
     // Outputs
     .c_drdy				(chk_drdy[5]),		 // Templated
     // Inputs
     .clk				(clk),
     .reset				(reset),
     .c_srdy				(chk_srdy[5]),		 // Templated
     .c_addr				(chk_addr[5]),		 // Templated
     .c_data				(chk_data[5]));		 // Templated

  bf_seq_check #(.width(width)) chk6
    (/*AUTOINST*/
     // Outputs
     .c_drdy				(chk_drdy[6]),		 // Templated
     // Inputs
     .clk				(clk),
     .reset				(reset),
     .c_srdy				(chk_srdy[6]),		 // Templated
     .c_addr				(chk_addr[6]),		 // Templated
     .c_data				(chk_data[6]));		 // Templated

  bf_seq_check #(.width(width)) chk7
    (/*AUTOINST*/
     // Outputs
     .c_drdy				(chk_drdy[7]),		 // Templated
     // Inputs
     .clk				(clk),
     .reset				(reset),
     .c_srdy				(chk_srdy[7]),		 // Templated
     .c_addr				(chk_addr[7]),		 // Templated
     .c_data				(chk_data[7]));		 // Templated

/* sd_bf8 AUTO_TEMPLATE
 (
   .p_addr (chk_addr),
   .c_addr (dest_matrix),
     .p_\(.*\)   (chk_\1),
     .c_\(.*\)   (gen_\1),
 );
 */
  sd_bf8 #(.width(width), .abits(abits)) bf8
    (/*AUTOINST*/
     // Outputs
     .c_drdy				(gen_drdy),		 // Templated
     .p_srdy				(chk_srdy),		 // Templated
     .p_addr				(chk_addr),		 // Templated
     .p_data				(chk_data),		 // Templated
     // Inputs
     .clk				(clk),
     .c_srdy				(gen_srdy),		 // Templated
     .p_drdy				(chk_drdy),		 // Templated
     .c_addr				(dest_matrix),		 // Templated
     .c_data				(gen_data),		 // Templated
     .reset				(reset));

  task set_rep_count;
    input [31:0] rep_count;
    begin
      gen0.rep_count = rep_count;
      gen1.rep_count = rep_count;
      gen2.rep_count = rep_count;
      gen3.rep_count = rep_count;
      gen4.rep_count = rep_count;
      gen5.rep_count = rep_count;
      gen6.rep_count = rep_count;
      gen7.rep_count = rep_count;
    end
  endtask

  task set_all_gen;
    input [7:0] srdy_pat;
    begin
      gen0.srdy_pat = srdy_pat;
      gen1.srdy_pat = srdy_pat;
      gen2.srdy_pat = srdy_pat;
      gen3.srdy_pat = srdy_pat;
      gen4.srdy_pat = srdy_pat;
      gen5.srdy_pat = srdy_pat;
      gen6.srdy_pat = srdy_pat;
      gen7.srdy_pat = srdy_pat;
    end
  endtask

  task set_gen;
    input [2:0] select;
    input [7:0] srdy_pat;
    begin
      case (select)
      0 : gen0.srdy_pat = srdy_pat;
      1 : gen1.srdy_pat = srdy_pat;
      2 : gen2.srdy_pat = srdy_pat;
      3 : gen3.srdy_pat = srdy_pat;
      4 : gen4.srdy_pat = srdy_pat;
      5 : gen5.srdy_pat = srdy_pat;
      6 : gen6.srdy_pat = srdy_pat;
      7 : gen7.srdy_pat = srdy_pat;
      endcase
    end
  endtask


  task set_all_chk;
    input [7:0] drdy_pat;
    begin
      chk0.drdy_pat = drdy_pat;
      chk1.drdy_pat = drdy_pat;
      chk2.drdy_pat = drdy_pat;
      chk3.drdy_pat = drdy_pat;
      chk4.drdy_pat = drdy_pat;
      chk5.drdy_pat = drdy_pat;
      chk6.drdy_pat = drdy_pat;
      chk7.drdy_pat = drdy_pat;
    end
  endtask

  task set_exp_dest;
    input [abits-1:0] mon_id;
    input [abits-1:0] exp_src;
    begin
      case (mon_id)
      0 : chk0.exp_addr = exp_src;
      1 : chk1.exp_addr = exp_src;
      2 : chk2.exp_addr = exp_src;
      3 : chk3.exp_addr = exp_src;
      4 : chk4.exp_addr = exp_src;
      5 : chk5.exp_addr = exp_src;
      6 : chk6.exp_addr = exp_src;
      7 : chk7.exp_addr = exp_src;
      endcase
    end
  endtask

  function [31:0] all_rep_count;
    input foo;
    begin
      all_rep_count = gen0.rep_count + gen1.rep_count + gen2.rep_count +
             gen3.rep_count + gen4.rep_count + gen5.rep_count +
             gen6.rep_count + gen7.rep_count;
    end
  endfunction

  function [31:0] all_ok_count;
    input foo;
    begin
      all_ok_count = chk0.ok_cnt + chk1.ok_cnt + chk2.ok_cnt +
             chk3.ok_cnt + chk4.ok_cnt + chk5.ok_cnt +
             chk6.ok_cnt + chk7.ok_cnt;
    end
  endfunction

  initial
    begin
`ifdef MODEL_TECH
      $wlfdumpvars(0, bench_mux_demux);
`else
      $dumpfile("mux_demux.vcd");
      $dumpvars;
`endif
      for (i=0; i<8; i=i+1)
        begin
          dest_matrix[i] = (i+3) % 8;
          set_exp_dest(i, i);
        end
      reset = 1;
      #100;
      reset = 0;

      set_rep_count(1000);
      //gen0.rep_count = 100;

      // burst normal data for 20 cycles
      repeat (20) @(posedge clk);

      set_all_gen(8'h5A);
      repeat (20) @(posedge clk);

      set_all_chk(8'hA5);
      repeat (40) @(posedge clk);

      // check FIFO overflow
      set_all_gen(8'hFD);
      set_all_chk(8'h03);
      repeat (100) @(posedge clk);

      // check FIFO underflow
      set_all_gen(8'h11);
      set_all_chk(8'hEE);
      repeat (100) @(posedge clk);

      for (i=0; i<8; i=i+1)
        begin
          set_gen(i, {$random} | (1 << ($random % 8)));
        end

      while (all_rep_count(0) > 0)
        @(posedge clk);

      // wait 20 cc for last data to propagate
      repeat (20) @(posedge clk);

      if (all_ok_count(0) >= 8000)
        $display ("----- TEST PASSED -----");
      else
        begin
          $display ("***** TEST FAILED *****");
          $display ("Ok count=%4d", all_ok_count(0));
        end

      #100;
      $finish;
    end

endmodule // bench_fifo_s
// Local Variables:
// verilog-library-directories:("." "/Users/guy/devel/sdlib-stash/env/verilog/common" "../common" "../../../rtl/verilog/buffers")
// End:
