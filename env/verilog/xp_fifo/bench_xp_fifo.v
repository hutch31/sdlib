`timescale 1ns/1ns

module bench_fifo_b;

  reg clk, reset;

  localparam width = 246, depth=16;  //, asz=$clog2(depth), usz=$clog2(depth+1);

  initial clk = 0;
  always #10 clk = ~clk;

 
  reg fail;
  /*AUTOWIRE*/
  // Beginning of automatic wires (for undeclared instantiated-module outputs)
  wire [245:0]          chk_data;               // From p_data of xp_fifo_.v
  wire                  chk_drdy;               // From chk of sd_seq_check.v
  wire                  chk_srdy;               // From p_srdy of xp_fifo_.v
  wire [6:0]            chk_usage;              // From c_usage of xp_fifo_.v
  wire [245:0]          gen_data;               // From gen of sd_seq_gen.v
  wire                  gen_drdy;               // From c_drdy of xp_fifo_.v
  wire                  gen_srdy;               // From c_srdy of sd_seq_gen.v
  wire [6:0]            gen_usage;              // From p_usage of xp_fifo_.v
 
  wire [6:0] 		next_usage;
  wire [245:0]    	ref_chk_data;
  wire   	        ref_chk_srdy;
  wire 		        ref_gen_drdy;
  wire [6:0]            ref_chk_usage;
  wire [6:0]            ref_gen_usage; 
 // End of automatics
 
  wire [1:0] 	 bist_done_pass_out_port;
  wire [1:0]     bist_done_fail_out_port;
  wire [13:0]    fifo_ptr_rd_data_port;
  wire [245:0]   cfg_rd_data_port;	
  wire		 fifo_fault;
   
/* sd_seq_gen AUTO_TEMPLATE
 (
 .p_\(.*\)   (gen_\1[]),
 );
 */
  sd_seq_gen #(width) gen
    (/*AUTOINST*/
     // Outputs
     .p_srdy                            (gen_srdy),              // Templated
     .p_data                            (gen_data[245:0]),   // Templated
     // Inputs
     .clk                               (clk),
     .reset                             (reset),
     .p_drdy                            (gen_drdy));              // Templated

/* sd_seq_check AUTO_TEMPLATE
 (
 .c_\(.*\)   (chk_\1[]),
 );
 */
  sd_seq_check #(width) chk
    (/*AUTOINST*/
     // Outputs
     .c_drdy                            (chk_drdy),              // Templated
     // Inputs
     .clk                               (clk),
     .reset                             (reset),
     .c_srdy                            (chk_srdy),              // Templated
     .c_data                            (chk_data[245:0]));   // Templated
/* sd_fifo_b AUTO_TEMPLATE
 (
     .p_\(.*\)   (chk_\1[]),
     .c_\(.*\)   (gen_\1[]),
 );
 */
  xp_fifo_sr64x246_s  xp_fifo
    (
    
     .c_data                            (gen_data),              // Templated
     .c_srdy                            (gen_srdy),              // Templated
     .cfg_addr				(6'h0),
     .cfg_rd_req			(1'b0),
     .cfg_wr_data			(246'h0),
     .cfg_wr_req			(1'b0),
     // diag hooks
     .enqEn				(1'b1),
     .deqEn				(1'b1),
     .contEnq 				(1'b0),
     .contDeq				(1'b0),
     .fifo_ptr_rd_req			(1'b0),	
     .fifo_ptr_rd_ack			(fifo_ptr_rd_ack),
     .fifo_ptr_rd_data                  (fifo_ptr_rd_data_port[13:0]),
     .fifo_ptr_wr_req   	        (1'b0),
     .fifo_ptr_wr_ack			(fifo_ptr_wr_ack),
     .fifo_ptr_wr_data                  (14'b0), 

     .clk				(clk),
     .rst				(reset),
     .p_drdy				(chk_drdy),

     .bist_run				(2'b0),
     .bist_rpr_mode			(1'b0),
     .bist_ptrn_fill			(1'b0),
     .bist_mem_rst			(1'b0),
     .bist_done_pass_out		(bist_done_pass_out_port[1:0]),
     .bist_done_fail_out		(bist_done_fail_out_port[1:0]),

     .flip_db_ecc			(1'b0),
     .flip_sb_ecc			(1'b0),
     .c_drdy				(gen_drdy),
     .c_usage				(gen_usage),
     .cfg_rd_ack			(cfg_rd_ack),
     .cfg_rd_data			(cfg_rd_data_port[245:0]),
     .cfg_wr_ack			(cfg_wr_ack),
     .db_err				(db_err),
     .p_data				(chk_data[245:0]),
     .p_srdy				(chk_srdy),
     .p_usage				(chk_usage[6:0]),
     .sb_err				(sb_err));


 sd_fifo_tailwr #(width,0,64,6) fifo_tailwr
    (/*AUTOINST*/
     // Outputs
     .c_drdy                            (ref_gen_drdy),              // Templated
     .usage                             (ref_chk_usage[6:0]),        // Templated
     .p_srdy                            (ref_chk_srdy),              // Templated
     .p_data                            (ref_chk_data[width-1:0]),   // Templated
     .nxt_usage 			(next_usage[6:0]),
      // Inputs
     .clk                               (clk),
     .reset                             (reset),
     .c_srdy                            (gen_srdy),              // Templated
     .c_data                            (gen_data[width-1:0]),   // Templated
     .p_drdy                            (chk_drdy));              // Templated
 
assert property (@(posedge clk) chk_usage == ref_chk_usage);   
initial
    begin
`ifdef VCS
      $vcdpluson;
`else
      $dumpfile("xp_c_fifo.lxt");
      $dumpvars;
`endif
      reset = 1;
      fail = 0;
      #100;
      reset = 0;
      repeat (5) @(posedge clk);

     test1();

     if (fail)
        $display ("!!!!! TEST FAILED !!!!!");
      else
        $display ("----- TEST PASSED -----");
      $finish;
    end // initial begin

   task end_check;
    begin
      if (chk.err_cnt > 0)
        fail = 1;
    end
  endtask
    

  // test basic overflow/underflow
  task test1;
    begin
      $display ("Running test 1");
      gen.rep_count = 9000;

      fork
        begin : traffic_gen
          gen.send (depth * 2);

          repeat (5) @(posedge clk);
          gen.srdy_pat = 8'h5A;
          gen.send (depth * 2);
     
          repeat (5) @(posedge clk);
          chk.drdy_pat = 8'hA5;
          gen.send (depth * 2);
      
          // check FIFO overflow
          repeat (5) @(posedge clk);
          gen.srdy_pat = 8'hFD;
          gen.send (depth * 4);

          // check FIFO underflow
          repeat (5) @(posedge clk);
          gen.srdy_pat = 8'h22;
          gen.send (depth * 4);

          repeat (20) @(posedge clk);
          disable t1_timeout;
        end // block: traffic_gen

        begin : t1_timeout
          repeat (500 * depth)
            @(posedge clk);
 
          fail = 1;
          disable traffic_gen;
          $display ("%t: ERROR: test1 timeout", $time);
        end
      join

      #500;
      end_check();
    end
  endtask // test1

endmodule // bench_fifo_s
// Local Variables:
// verilog-library-directories:("." "../common" "../../../rtl/verilog/buffers")
// End:
