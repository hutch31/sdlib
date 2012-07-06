// test module vc2sd, provides same interface using fifo head / tail
// and buffer as the standalone module

module vc2sd
  #(parameter depth=16,
    parameter asz=$clog2(depth),
    parameter width=8,
    parameter reginp=0
    )
    (
     /*AUTOINPUT*/
     // Beginning of automatic inputs (from unused autoinst inputs)
     input [(width)-1:0] c_data,                // To vchead of vc_fifo_head_s.v
     input              c_vld,                  // To vchead of vc_fifo_head_s.v
     input              clk,                    // To vchead of vc_fifo_head_s.v, ...
     input              p_drdy,                 // To tail of sd_fifo_tail_s.v
     input              reset,                  // To vchead of vc_fifo_head_s.v, ...
     // End of automatics
     /*AUTOOUTPUT*/
     // Beginning of automatic outputs (from unused autoinst outputs)
     output             c_cr,                   // From vchead of vc_fifo_head_s.v
     output [width-1:0] p_data,                 // From mem2p of behave2p_mem.v
     output             p_srdy                 // From tail of sd_fifo_tail_s.v
     // End of automatics
     );

  /*AUTOWIRE*/
  // Beginning of automatic wires (for undeclared instantiated-module outputs)
  wire [asz-1:0]        rd_addr;                // From tail of sd_fifo_tail_s.v
  wire                  rd_en;                  // From tail of sd_fifo_tail_s.v
  wire [asz:0]          rdptr_tail;             // From tail of sd_fifo_tail_s.v
  wire [asz-1:0]        wr_addr;                // From vchead of vc_fifo_head_s.v
  wire [(width)-1:0]    wr_data;                // From vchead of vc_fifo_head_s.v
  wire                  wr_en;                  // From vchead of vc_fifo_head_s.v
  wire [asz:0]          wrptr_head;             // From vchead of vc_fifo_head_s.v
  // End of automatics
  
    /* vc_fifo_head_s AUTO_TEMPLATE
   (
     .usage                             (),
   );
   */
  vc_fifo_head_s #(
                   // Parameters
                   .depth               (depth),
                   .width               (width),
                   .reginp              (reginp))
  vchead
    (/*AUTOINST*/
     // Outputs
     .c_cr                              (c_cr),
     .wrptr_head                        (wrptr_head[asz:0]),
     .wr_addr                           (wr_addr[asz-1:0]),
     .wr_en                             (wr_en),
     .wr_data                           (wr_data[(width)-1:0]),
     .usage                             (),                      // Templated
     // Inputs
     .clk                               (clk),
     .reset                             (reset),
     .c_vld                             (c_vld),
     .c_data                            (c_data[(width)-1:0]),
     .rdptr_tail                        (rdptr_tail[asz:0]));
  
/* behave2p_mem AUTO_TEMPLATE
    (.d_out (p_data[]),
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
     .d_out                             (p_data[width-1:0]),     // Templated
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
 );
 */
  sd_fifo_tail_s #(.depth(depth)) tail
    (/*AUTOINST*/
     // Outputs
     .rdptr_tail                        (rdptr_tail[asz:0]),
     .rd_en                             (rd_en),
     .rd_addr                           (rd_addr[asz-1:0]),
     .p_srdy                            (p_srdy),
     // Inputs
     .clk                               (clk),
     .reset                             (reset),
     .wrptr_head                        (wrptr_head[asz:0]),
     .p_drdy                            (p_drdy));

endmodule // vc2sd
// Local Variables:
// verilog-library-directories:("." "../common" "../../../rtl/verilog/buffers" "../../../rtl/verilog/utility" "../../../rtl/verilog/memory")
// End:
