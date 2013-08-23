//----------------------------------------------------------------------
// Srdy/Drdy FIFO Head "C"
//
// Building block for FIFOs.  The "C" (compact)
// FIFO is useful for building non-power of 2 FIFOs, which
// will be built entirely from flops.
//
// Parameters:
//   depth : depth/size of FIFO, in words
//   usz   : usage counter size
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

// Clocking statement for synchronous blocks.  Default is for
// posedge clocking and positive async reset
`ifndef SDLIB_CLOCKING 
 `define SDLIB_CLOCKING posedge clk or posedge reset
`endif

// delay unit for nonblocking assigns, default is to #1
`ifndef SDLIB_DELAY 
 `define SDLIB_DELAY #1 
`endif

module sd_fifo_c
  #(parameter width=8, 
    parameter depth=16,
    parameter usz=$clog2(depth+1)
    )
    (
     input       clk,
     input       reset,
     input       c_srdy,
     output      c_drdy,
     input [width-1:0] c_data,
     output logic [usz-1:0]    usage,

     output logic    p_srdy,
     input       p_drdy,
     output  [width-1:0] p_data
     );

  localparam asz = $clog2(depth);
  localparam npt = (depth != (2**asz));

  logic [asz-1:0]           wrptr, nxt_wrptr;
  logic [asz-1:0]           wrptr_p1;
  logic [asz-1:0]           rdptr, nxt_rdptr;
  logic [asz-1:0]           rdptr_p1;
  logic                     full;
  logic [usz-1:0]           nxt_usage;
  logic [width-1:0]         mem [0:depth-1];
  logic                     wr_en, rd_en;
  logic                     nxt_p_srdy;
  logic [asz-1:0]           r_addr;
  
  assign c_drdy = !full;
  //assign wr_addr = wrptr[asz-1:0];
   
  always @*
    begin
      if (npt)
        begin
          if (wrptr == (depth-1))
            wrptr_p1 = 0;
          else
            wrptr_p1 =  wrptr + 1;
        end
      else
        wrptr_p1 = wrptr + 1;
      
      full = (usage == (depth));
          
      if (c_srdy & !full)
        nxt_wrptr = wrptr_p1;
      else
        nxt_wrptr = wrptr;

      wr_en = (c_srdy & !full);
    end

  always @*
    begin
      if (npt)
        begin
          if (rdptr == (depth-1))
            rdptr_p1 = 0;
          else
            rdptr_p1 =  rdptr + 1;
        end
      else
        rdptr_p1 = rdptr + 1;
      
      //empty = (usage == 0);

      if (p_drdy & p_srdy)
        nxt_rdptr = rdptr_p1;
      else
        nxt_rdptr = rdptr;
          
      nxt_p_srdy = (p_srdy & ~p_drdy) | (~p_srdy & (usage > 0)) | (p_srdy & p_drdy & (usage > 1));
      rd_en = (p_srdy & p_drdy);
    end // always @ *

  always @*
    begin
      if (wr_en & !rd_en)
        nxt_usage = usage + 1;
      else if (rd_en & !wr_en)
        nxt_usage = usage - 1;
      else
        nxt_usage = usage;
    end
      
  always @(`SDLIB_CLOCKING)
    begin
      if (reset)
        begin
          p_srdy  <= `SDLIB_DELAY 0;
        end
      else
        begin
          p_srdy <= `SDLIB_DELAY nxt_p_srdy;
        end // else: !if(reset)
    end // always @ (posedge clk)

  always @(`SDLIB_CLOCKING)
    begin
      if (reset)
        begin
          wrptr <= `SDLIB_DELAY 0;
          rdptr <= `SDLIB_DELAY 0;
          usage <= `SDLIB_DELAY 0;
        end
      else
        begin
          wrptr <= `SDLIB_DELAY nxt_wrptr;
          rdptr <= `SDLIB_DELAY nxt_rdptr;
          usage <= `SDLIB_DELAY nxt_usage;
        end
   end // always @ (posedge clk)

  behave2p_mem #(.width (width),
                 .depth (depth),
                 .addr_sz (asz),
                 .reg_rd_addr (0))
  mem2p
  (
   .wr_en (wr_en),
   .rd_en  (1'b1),
   .wr_clk (clk),
   .rd_clk (1'b0),
   .d_in   (c_data),
   .wr_addr (wrptr),
   .rd_addr (rdptr),
   .d_out   (p_data));
  
endmodule
