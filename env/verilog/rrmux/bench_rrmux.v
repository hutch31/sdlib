module bench_rrmux;

`define TEST_VECS 1000
`define SDLIB_DELAY #0  
  reg clk, reset;
  reg rrmux_rearb;
   reg [7:0] rearb_pat;
 
  
  localparam pat_dep = 8;
  parameter sim_mode = 2;
  integer err_cnt;
  integer i,j;
   
  initial err_cnt = 0;
  initial clk = 0;
  initial j = 0;
  initial i = 0;
  initial rrmux_rearb = 1'b1;
  initial rearb_pat = 8'hf1;
   
  always clk = #5 ~clk;
   always@(posedge clk)
     begin
	rrmux_rearb = rearb_pat[j];
	j=j+1;
	if(j>7) j= 0;
     end
   
   /*AUTOWIRE*/
  // Beginning of automatic wires (for undeclared instantiated-module outputs)
  wire [31:0]           in_data;                // From gen0 of sd_seq_gen.v, ...
  wire [3:0]            in_drdy;                // From rrmux of sd_rrmux.v
  wire [3:0]            in_srdy;                // From gen0 of sd_seq_gen.v, ...
  wire [7:0]            mm_data;                // From rrmux of sd_rrmux.v
  wire                  mm_drdy;                // From mirror of sd_mirror.v
  wire [3:0]            mm_grant;               // From rrmux of sd_rrmux.v
  wire                  mm_srdy;                // From rrmux of sd_rrmux.v
  wire [7:0]            out_data;               // From mirror of sd_mirror.v
  wire [3:0]            out_drdy;               // From check0 of sd_seq_check.v, ...
  wire [3:0]            out_srdy;               // From mirror of sd_mirror.v
  // End of automatics
  
/* sd_seq_gen AUTO_TEMPLATE
 (
     .width (8),
     .tag_val (2'd@),
     .tag_sz  (2),
     .x_inval (1),
     .p_srdy                            (in_srdy[@]),
     .p_drdy                            (in_drdy[@]),
     .p_data                            (in_data[@"(+ 7 (* @ 8))":@"(* @ 8)"]),
 );
 */
  sd_seq_gen #(/*AUTOINSTPARAM*/
               // Parameters
               .width                   (8),                     // Templated
               .tag_sz                  (2),                     // Templated
               .tag_val                 (2'd0),                  // Templated
               .x_inval                 (1),                     // Templated
               .pat_dep                 (pat_dep))  gen0
    (/*AUTOINST*/
     // Outputs
     .p_srdy                            (in_srdy[0]),            // Templated
     .p_data                            (in_data[7:0]),          // Templated
     // Inputs
     .clk                               (clk),
     .reset                             (reset),
     .p_drdy                            (in_drdy[0]));            // Templated
  
  sd_seq_gen #(/*AUTOINSTPARAM*/
               // Parameters
               .width                   (8),                     // Templated
               .tag_sz                  (2),                     // Templated
               .tag_val                 (2'd1),                  // Templated
               .x_inval                 (1),                     // Templated
               .pat_dep                 (pat_dep))  gen1
    (/*AUTOINST*/
     // Outputs
     .p_srdy                            (in_srdy[1]),            // Templated
     .p_data                            (in_data[15:8]),         // Templated
     // Inputs
     .clk                               (clk),
     .reset                             (reset),
     .p_drdy                            (in_drdy[1]));            // Templated
  
  sd_seq_gen #(/*AUTOINSTPARAM*/
               // Parameters
               .width                   (8),                     // Templated
               .tag_sz                  (2),                     // Templated
               .tag_val                 (2'd2),                  // Templated
               .x_inval                 (1),                     // Templated
               .pat_dep                 (pat_dep))  gen2
    (/*AUTOINST*/
     // Outputs
     .p_srdy                            (in_srdy[2]),            // Templated
     .p_data                            (in_data[23:16]),        // Templated
     // Inputs
     .clk                               (clk),
     .reset                             (reset),
     .p_drdy                            (in_drdy[2]));            // Templated
  
  sd_seq_gen #(/*AUTOINSTPARAM*/
               // Parameters
               .width                   (8),                     // Templated
               .tag_sz                  (2),                     // Templated
               .tag_val                 (2'd3),                  // Templated
               .x_inval                 (1),                     // Templated
               .pat_dep                 (pat_dep))  gen3
    (/*AUTOINST*/
     // Outputs
     .p_srdy                            (in_srdy[3]),            // Templated
     .p_data                            (in_data[31:24]),        // Templated
     // Inputs
     .clk                               (clk),
     .reset                             (reset),
     .p_drdy                            (in_drdy[3]));            // Templated
  
 /* sd_rrmux AUTO_TEMPLATE
 (
     .c_drdy                            (in_drdy[3:0]),
     .c_data                            (in_data[(8*4)-1:0]),
     .c_srdy                            (in_srdy[]),
     .c_rearb                           (1'b1),
  
     .p_data                            (mm_data[7:0]),
     .p_grant                           (mm_grant[]),
     .p_srdy                            (mm_srdy),
     .p_drdy                            (mm_drdy),
   );
  */
  sd_rrmux #(
             // Parameters
             .width                     (8),
             .inputs                    (4),
             .mode                      (sim_mode),
             .fast_arb                  (1)) rrmux
    (/*AUTOINST*/
     // Outputs
     .c_drdy                            (in_drdy[3:0]),          // Templated
     .p_data                            (mm_data[7:0]),          // Templated
     .p_grant                           (mm_grant[3:0]),         // Templated
     .p_srdy                            (mm_srdy),               // Templated
     // Inputs
     .clk                               (clk),
     .reset                             (reset),
     .c_data                            (in_data[(8*4)-1:0]),    // Templated
     .c_srdy                            (in_srdy[3:0]),          // Templated
     .c_rearb                           (rrmux_rearb),                  // Templated
     .p_drdy                            (mm_drdy));               // Templated

  wire [3:0] mm_dst_vld;
  assign mm_dst_vld = 1 << mm_data[7:6];
  
/* sd_mirror AUTO_TEMPLATE
 (
     .c_data                            (mm_data[]),
     .c_srdy                            (mm_srdy),
     .c_drdy                            (mm_drdy),
     .c_dst_vld                         (mm_dst_vld[]),
     .p_srdy                            (out_srdy[]),
     .p_data                            (out_data[]),
     .p_drdy                            (out_drdy[])); 
 );
 */
  sd_mirror #(
              // Parameters
              .mirror                   (4),
              .width                    (8))  mirror
    (/*AUTOINST*/
     // Outputs
     .c_drdy                            (mm_drdy),               // Templated
     .p_srdy                            (out_srdy[3:0]),         // Templated
     .p_data                            (out_data[7:0]),         // Templated
     // Inputs
     .clk                               (clk),
     .reset                             (reset),
     .c_srdy                            (mm_srdy),               // Templated
     .c_data                            (mm_data[7:0]),          // Templated
     .c_dst_vld                         (mm_dst_vld[3:0]),       // Templated
     .p_drdy                            (out_drdy[3:0]));         // Templated

  
/* sd_seq_check AUTO_TEMPLATE
 (
     .width (8),
     .tag_val (2'd@),
     .tag_sz  (2),
     .x_inval (1),
     .c_srdy                            (out_srdy[@]),
     .c_drdy                            (out_drdy[@]),
     .c_data                            (out_data[7:0]),
 );
 */
  sd_seq_check #(/*AUTOINSTPARAM*/
                 // Parameters
                 .width                 (8),                     // Templated
                 .tag_sz                (2),                     // Templated
                 .tag_val               (2'd0))                  // Templated
  check0
      (/*AUTOINST*/
       // Outputs
       .c_drdy                          (out_drdy[0]),           // Templated
       // Inputs
       .clk                             (clk),
       .reset                           (reset),
       .c_srdy                          (out_srdy[0]),           // Templated
       .c_data                          (out_data[7:0]));         // Templated

  sd_seq_check #(/*AUTOINSTPARAM*/
                 // Parameters
                 .width                 (8),                     // Templated
                 .tag_sz                (2),                     // Templated
                 .tag_val               (2'd1))                  // Templated
    check1
      (/*AUTOINST*/
       // Outputs
       .c_drdy                          (out_drdy[1]),           // Templated
       // Inputs
       .clk                             (clk),
       .reset                           (reset),
       .c_srdy                          (out_srdy[1]),           // Templated
       .c_data                          (out_data[7:0]));         // Templated

  sd_seq_check #(/*AUTOINSTPARAM*/
                 // Parameters
                 .width                 (8),                     // Templated
                 .tag_sz                (2),                     // Templated
                 .tag_val               (2'd2))                  // Templated
    check2
      (/*AUTOINST*/
       // Outputs
       .c_drdy                          (out_drdy[2]),           // Templated
       // Inputs
       .clk                             (clk),
       .reset                           (reset),
       .c_srdy                          (out_srdy[2]),           // Templated
       .c_data                          (out_data[7:0]));         // Templated

  sd_seq_check #(/*AUTOINSTPARAM*/
                 // Parameters
                 .width                 (8),                     // Templated
                 .tag_sz                (2),                     // Templated
                 .tag_val               (2'd3))                  // Templated
    check3
      (/*AUTOINST*/
       // Outputs
       .c_drdy                          (out_drdy[3]),           // Templated
       // Inputs
       .clk                             (clk),
       .reset                           (reset),
       .c_srdy                          (out_srdy[3]),           // Templated
       .c_data                          (out_data[7:0]));         // Templated

  reg        fail;
  integer    i;
  
  initial
    begin
     `ifdef VCS
	$vcdpluson;
     `else
	$dumpfile ("bench_rrmux.vcd");
        $dumpvars;
     `endif

/*      reset = 1;
      #100;
      reset = 0;
      #100;
      gen0.srdy_pat = 8'h0F;
      gen1.srdy_pat = 8'hF0;
      gen2.srdy_pat = 8'h5A;
      gen3.srdy_pat = 8'hA5;
      fork
        gen0.send (`TEST_VECS);
        gen1.send (`TEST_VECS);
        gen2.send (`TEST_VECS);
        gen3.send (`TEST_VECS);
      join
    //  #100;
    //  wait (gen0.rep_count == 0)
    //  #100;

      if (err_cnt == 0)
        $display ("----- TEST PASSED -----");
      else
        begin
          $display ("***** TEST FAILED *****");
        end
      $finish;
    end
  */
       reset = 1;
       gen0.rep_count = 0;
       gen1.rep_count = 0;
       gen2.rep_count = 0;
       gen3.rep_count = 0;
       fail = 0;
       rrmux_rearb = 0;
       
       #100;
       reset = 0;

       do_reset();
       test1();
       if(fail)
	 $display("!!!!! TEST 1 FAILED !!!!!!");
       else
	 $display("----- TEST 1 PASED -----");
  
       $finish;
    end // initial begin

   task do_reset;
      begin
	 gen0.rep_count = 0;
	 gen1.rep_count = 0;
	 gen2.rep_count = 0;
	 gen3.rep_count = 0;
	 reset = 1;
	 repeat(5)@(posedge clk);
	 reset = 0;
	 repeat(10)@(posedge clk);
      end
   endtask //do_reset

   task end_check;
      begin
	 if (err_cnt > 0)
	   fail = 1;
      end
   endtask // end_check

   task test1;   //test mode0
      begin
	 $display("Running test 1"); 
	 gen0.srdy_pat = 8'h0F;
	 gen1.srdy_pat = 8'hF0;
	 gen2.srdy_pat = 8'h5A;
	 gen3.srdy_pat = 8'hA5;
	 fork
            gen0.send (`TEST_VECS);
            gen1.send (`TEST_VECS);
            gen2.send (`TEST_VECS);
            gen3.send (`TEST_VECS);
	 join
	 #100;
	 end_check();
      end
   endtask  //end task 1

 
endmodule // bench_rrmux
// Local Variables:
// verilog-library-directories:("."  "../../../rtl/verilog/forks")
// End:
