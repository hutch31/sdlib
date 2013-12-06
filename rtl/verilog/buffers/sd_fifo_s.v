//----------------------------------------------------------------------
// Srdy/Drdy FIFO "S"
//
// Building block for FIFOs.  The "S" (small or synchronizer) FIFO is 
// designed for smaller FIFOs based around memories or flops, with 
// sizes that are a power of 2.
//
// The "S" FIFO can be used as a two-clock asynchronous FIFO.  When the
// async parameter is set to 1, the pointers will be converted from
// binary to grey code and double-synchronized.
//
// All synchronizer flops start with "hgff" for replacement during
// synthesis with high-gain flops.
//
// Naming convention: c = consumer, p = producer, i = internal interface
//----------------------------------------------------------------------
// Author: Guy Hutchison
//
//----------------------------------------------------------------------
// This is free and unencumbered software released into the public domain.
//
// Anyone is free to copy, modify, publish, use, compile, sell, or
// distribute this software, either in source code form or as a compiled
// binary, for any purpose, commercial or non-commercial, and by any
// means.
//
// In jurisdictions that recognize copyright laws, the author or authors
// of this software dedicate any and all copyright interest in the
// software to the public domain. We make this dedication for the benefit
// of the public at large and to the detriment of our heirs and
// successors. We intend this dedication to be an overt act of
// relinquishment in perpetuity of all present and future rights to this
// software under copyright law.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
// IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
// OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
// ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
// OTHER DEALINGS IN THE SOFTWARE.
//
// For more information, please refer to <http://unlicense.org/> 
//----------------------------------------------------------------------

// delay unit for nonblocking assigns, default is to #1
`ifndef SDLIB_DELAY 
 `define SDLIB_DELAY #1 
`endif

module sd_fifo_s
  #(parameter width=8,
    parameter depth=16,
    parameter async=0,
    parameter asz=$clog2(depth)
    )
    (
     input       c_clk,
     input       c_reset,
     input       c_srdy,
     output      c_drdy,
     input [width-1:0] c_data,
     output [asz:0]    c_usage,

     input       p_clk,
     input       p_reset,
     output      p_srdy,
     input       p_drdy,
     output  [width-1:0] p_data,
     output [asz:0]      p_usage
     );

  wire                  rd_en;
  wire [asz:0]          rdptr_tail, rdptr_tail_sync;
  wire                  wr_en;
  wire [asz:0]          wrptr_head, wrptr_head_sync;
  wire [asz-1:0]        rd_addr, wr_addr;

  behave2p_mem #(.width(width), .depth(depth)) mem2p
    (.d_out (p_data),
     .wr_en (wr_en),
     .rd_en (rd_en),
     .wr_clk (c_clk),
     .wr_addr (wr_addr),
     .rd_clk  (p_clk),
     .rd_addr (rd_addr),
     .d_in    (c_data));


  sd_fifo_head_s #(.depth(depth), .async(async)) head
    (
     // Outputs
     .c_drdy                            (c_drdy),
     .wrptr_head                        (wrptr_head),
     .wr_en                             (wr_en),
     .wr_addr                           (wr_addr),
     .c_usage                           (c_usage),
     // Inputs
     .clk                               (c_clk),
     .reset                             (c_reset),
     .c_srdy                            (c_srdy),
     .rdptr_tail                        (rdptr_tail_sync));

  sd_fifo_tail_s #(.depth(depth), .async(async)) tail
    (
     // Outputs
     .rdptr_tail                        (rdptr_tail),
     .rd_en                             (rd_en),
     .rd_addr                           (rd_addr),
     .p_srdy                            (p_srdy),
     .p_usage                           (p_usage),
     // Inputs
     .clk                               (p_clk),
     .clken                             (1'b1),
     .reset                             (p_reset),
     .wrptr_head                        (wrptr_head_sync),
     .p_drdy                            (p_drdy));

  generate
    if (async)
      begin : gen_sync
        reg [asz:0] hgff_r_sync1, hgff_r_sync2;
        reg [asz:0] hgff_w_sync1, hgff_w_sync2;

        always @(posedge p_clk)
          begin
            hgff_w_sync1 <= `SDLIB_DELAY wrptr_head;
            hgff_w_sync2 <= `SDLIB_DELAY hgff_w_sync1;
          end

        always @(posedge c_clk)
          begin
            hgff_r_sync1 <= `SDLIB_DELAY rdptr_tail;
            hgff_r_sync2 <= `SDLIB_DELAY hgff_r_sync1;
          end

        assign wrptr_head_sync = hgff_w_sync2;
        assign rdptr_tail_sync = hgff_r_sync2;
      end
    else
      begin : gen_nosync
        assign wrptr_head_sync = wrptr_head;
        assign rdptr_tail_sync = rdptr_tail;
      end
  endgenerate   

endmodule // sd_fifo_s
