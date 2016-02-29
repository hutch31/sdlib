`timescale 1ns/1ns

module bench_ser_deser;

  reg clk, reset;

  localparam width = 9;
  localparam ser_width = 4;
  localparam [1:0] ser_ms_seg=2;
  localparam depth = 7;
  localparam usz = $clog2(depth+1);

  initial clk = 0;
  always #10 clk = ~clk;

  /*AUTOWIRE*/
  // Beginning of automatic wires (for undeclared instantiated-module outputs)
  logic [width-1:0]     chk_data;               // From fifo2 of sd_fifo_tailwr.v
  wire                  chk_drdy;               // From chk of sd_seq_check.v
  logic                 chk_srdy;               // From fifo2 of sd_fifo_tailwr.v
  wire [width-1:0]      gen_data;               // From gen of sd_seq_gen.v
  logic                 gen_drdy;               // From enmux of sd_serializer.v
  wire                  gen_srdy;               // From gen of sd_seq_gen.v
  logic [(ser_width)-1:0] int0_data;              // From enmux of sd_serializer.v
  logic                 int0_drdy;              // From fifo of sd_fifo_tailwr.v
  logic                 int0_ef;                // From enmux of sd_serializer.v
  logic                 int0_srdy;              // From enmux of sd_serializer.v
  logic [ser_width-1:0]   int1_data;              // From fifo of sd_fifo_tailwr.v
  logic                 int1_drdy;              // From demux of sd_deserializer.v
  logic                 int1_ef;                // From fifo of sd_fifo_tailwr.v
  logic                 int1_srdy;              // From fifo of sd_fifo_tailwr.v
  logic [width-1:0]     int2_data;              // From demux of sd_deserializer.v
  logic                 int2_drdy;              // From fifo2 of sd_fifo_tailwr.v
  logic                 int2_srdy;              // From demux of sd_deserializer.v
  // End of automatics

/* sd_seq_gen AUTO_TEMPLATE
 (
 .p_\(.*\)   (gen_\1[]),
 );
 */
  sd_seq_gen #(.width(width)) gen
    (/*AUTOINST*/
     // Outputs
     .p_srdy                            (gen_srdy),              // Templated
     .p_data                            (gen_data[width-1:0]),   // Templated
     // Inputs
     .clk                               (clk),
     .reset                             (reset),
     .p_drdy                            (gen_drdy));             // Templated

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
     .c_data                            (chk_data[width-1:0]));  // Templated

/* sd_serializer AUTO_TEMPLATE
 (
     .p_\(.*\)   (int0_\1[]),
     .c_ms_seg   (ser_ms_seg),
     .c_\(.*\)   (gen_\1[]),
 );
 */
  sd_serializer #(.PARA_WIDTH(width), .SER_WIDTH(ser_width)) enmux
    (/*AUTOINST*/
     // Outputs
     .c_drdy                            (gen_drdy),              // Templated
     .p_data                            (int0_data[(ser_width)-1:0]), // Templated
     .p_ef                              (int0_ef),               // Templated
     .p_srdy                            (int0_srdy),             // Templated
     // Inputs
     .c_data                            (gen_data[width-1:0]),   // Templated
     .c_ms_seg                          (ser_ms_seg),                 // Templated
     .c_srdy                            (gen_srdy),              // Templated
     .p_drdy                            (int0_drdy),             // Templated
     .clk                               (clk),
     .reset                             (reset));
   
/* sd_fifo_tailwr AUTO_TEMPLATE
 (
     .c_data     ({int0_data[ser_width-1:0], int0_ef}),
     .p_data     ({int1_data[ser_width-1:0], int1_ef}),
     .c_\(.*\)   (int0_\1[]),
     .p_\(.*\)   (int1_\1[]),
     ..*usage    (),
 );
 */
  sd_fifo_tailwr #(.width(ser_width+1), .depth(7)) fifo
    (/*AUTOINST*/
     // Outputs
     .c_drdy                            (int0_drdy),             // Templated
     .p_data                            ({int1_data[ser_width-1:0], int1_ef}), // Templated
     .p_srdy                            (int1_srdy),             // Templated
     .nxt_usage                         (),                      // Templated
     .usage                             (),                      // Templated
     // Inputs
     .clk                               (clk),
     .reset                             (reset),
     .c_data                            ({int0_data[ser_width-1:0], int0_ef}), // Templated
     .c_srdy                            (int0_srdy),             // Templated
     .p_drdy                            (int1_drdy));            // Templated

/* sd_deserializer AUTO_TEMPLATE
 (
     .p_\(.*\)   (int2_\1[]),
     .c_\(.*\)   (int1_\1[]),
 );
 */
  sd_deserializer #(.PARA_WIDTH(width), .SER_WIDTH(ser_width)) demux
    (/*AUTOINST*/
     // Outputs
     .c_drdy                            (int1_drdy),             // Templated
     .p_data                            (int2_data[width-1:0]),  // Templated
     .p_srdy                            (int2_srdy),             // Templated
     // Inputs
     .c_data                            (int1_data[(ser_width)-1:0]), // Templated
     .c_ef                              (int1_ef),               // Templated
     .c_srdy                            (int1_srdy),             // Templated
     .p_drdy                            (int2_drdy),             // Templated
     .clk                               (clk),
     .reset                             (reset));

/* sd_fifo_tailwr AUTO_TEMPLATE
 (
     .c_\(.*\)   (int2_\1[]),
     .p_\(.*\)   (chk_\1[]),
     ..*usage    (),
 );
 */
  sd_fifo_tailwr #(.width(width), .depth(7)) fifo2
    (/*AUTOINST*/
     // Outputs
     .c_drdy                            (int2_drdy),             // Templated
     .p_data                            (chk_data[width-1:0]),   // Templated
     .p_srdy                            (chk_srdy),              // Templated
     .nxt_usage                         (),                      // Templated
     .usage                             (),                      // Templated
     // Inputs
     .clk                               (clk),
     .reset                             (reset),
     .c_data                            (int2_data[width-1:0]),  // Templated
     .c_srdy                            (int2_srdy),             // Templated
     .p_drdy                            (chk_drdy));             // Templated
  initial
    begin
`ifdef MODEL_TECH
      $wlfdumpvars(0, bench_ser_deser);
`else
      //$dumpfile("mux_demux.vcd");
      //$dumpvars;
      $vcdpluson();
`endif
      reset = 1;
      #100;
      reset = 0;

      gen.rep_count = 9000;

      // burst normal data for 20 cycles
      repeat (20) @(posedge clk);

      gen.srdy_pat = 8'h5A;
      repeat (20) @(posedge clk);

      chk.drdy_pat = 8'hA5;
      repeat (40) @(posedge clk);

      // check FIFO overflow
      gen.srdy_pat = 8'hFD;
      chk.drdy_pat = 8'h03;
      repeat (100) @(posedge clk);

      // check FIFO underflow
      gen.srdy_pat = 8'h11;
      chk.drdy_pat = 8'hEE;
      repeat (100) @(posedge clk);

      // Run out the remainder of the repeat count
      fork
        begin : runout
          while (gen.rep_count > 0) 
            begin
              gen.srdy_pat = {$random} | (1 << ($random % 8));
              chk.drdy_pat = {$random} | (1 << ($random % 8));
              repeat (16) @(posedge clk);
            end
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
// verilog-library-directories:("." "../common" "../../../rtl/verilog/*")
// verilog-auto-inst-param-value:t
// End:
