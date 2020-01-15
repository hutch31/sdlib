//----------------------------------------------------------------------
// Srdy/Drdy FIFO Head "S"
//
// Building block for FIFOs.  The "S" (small/sync) FIFO is design for smaller
// FIFOs based around memories or flops, with sizes that are a power of 2.
//
// The "S" FIFO can be used as a two-clock asynchronous FIFO.
//
// Parameters:
//   depth : depth/size of FIFO, in words
//   asz   : address size, automatically computed from depth
//   async : 1 for clock-synchronization FIFO, 0 for normal
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
`ifdef SDLIB_ASYNC_RESET
 `define SDLIB_CLOCKING posedge clk or posedge reset
`else
 `define SDLIB_CLOCKING posedge clk
`endif

// delay unit for nonblocking assigns, default is to #1
`ifndef SDLIB_DELAY
 `define SDLIB_DELAY #1
`endif

module sd_fifo_head_s
  #(parameter depth=16,
    parameter async=0,
    parameter asz=$clog2(depth)
    )
    (
     input       clk,
     input       reset,
     input       c_srdy,
     output      c_drdy,

     output reg [asz:0] wrptr_head,
     output [asz-1:0]   wr_addr,
     output reg         wr_en,
     input [asz:0]      rdptr_tail,

     output reg [asz:0] c_usage

     );

  reg [asz:0]           wrptr, nxt_wrptr;
  reg [asz:0]           wrptr_p1;
  reg                   full;
  wire [asz:0]          rdptr;

  assign c_drdy = !full;
  assign wr_addr = wrptr[asz-1:0];

  always @*
    begin
      wrptr_p1 = wrptr + 1;

      full = ((wrptr[asz-1:0] == rdptr[asz-1:0]) &&
              (wrptr[asz] == ~rdptr[asz]));

      if (c_srdy & !full)
        nxt_wrptr = wrptr_p1;
      else
        nxt_wrptr = wrptr;

      wr_en = (c_srdy & !full);

      if (wrptr[asz] == rdptr[asz])
        c_usage = wrptr - rdptr;
      else
        c_usage = (wrptr[asz-1:0] + depth) - rdptr[asz-1:0]; // cn_lint_off_line CN_UNEQUAL_LEN
    end

  generate if (async == 0)
    begin : sync_wptr
      always @(`SDLIB_CLOCKING)
        begin
          if (reset)
            wrptr <= `SDLIB_DELAY 0;
          else
            wrptr <= `SDLIB_DELAY nxt_wrptr;
        end // always @ (posedge clk)

      always @*
        wrptr_head = wrptr;
    end // block: sync_wptr
  else
    begin : async_wptr
      always @(`SDLIB_CLOCKING)
        begin
          if (reset)
            wrptr_head <= `SDLIB_DELAY 0;
          else
            wrptr_head <= `SDLIB_DELAY bin2grey (nxt_wrptr);
        end

      always @*
        wrptr = grey2bin(wrptr_head);
    end
  endgenerate

  function [asz:0] bin2grey;
    input [asz:0] bin_in;
    integer       b;
    begin
      bin2grey[asz] = bin_in[asz];
      for (b=0; b<asz; b=b+1)
        bin2grey[b] = bin_in[b] ^ bin_in[b+1]; // cn_lint_off_line CN_RANGE_UFLOW
    end
  endfunction // for

  function [asz:0] grey2bin;
    input [asz:0] grey_in;
    integer       b;
    begin
      grey2bin[asz] = grey_in[asz];
      for (b=asz-1; b>=0; b=b-1)
        grey2bin[b] = grey_in[b] ^ grey2bin[b+1]; // cn_lint_off_line CN_RANGE_UFLOW
    end
  endfunction

  assign rdptr = (async)? grey2bin(rdptr_tail) : rdptr_tail;

endmodule
