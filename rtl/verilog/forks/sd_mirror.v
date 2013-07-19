//----------------------------------------------------------------------
//  Srdy/drdy mirrored fork
//
//  Used when a single item of data needs to be used by more than one
//  block, and all blocks may finish at different times.  This creates
//  separate srdy/drdy signals for each block, and holds drdy to the
//  sender until all blocks have individually asserted drdy.
//
//  The input c_dst_vld allows the data to be selectively sent to some
//  or all of the downstream endpoints.  At least one bit in c_dst_vld
//  must be asserted with c_srdy.  If this functionality is not desired
//  the input should be tied to 0.
//
// Naming convention: c = consumer, p = producer, i = internal interface
//----------------------------------------------------------------------
//  Author: Guy Hutchison
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

module sd_mirror
  #(parameter mirror=2,
    parameter width=128)
  (input        clk,
   input        reset,

   input              c_srdy,
   //output reg         c_drdy,
   output             c_drdy,
   input [width-1:0]  c_data,
   input [mirror-1:0] c_dst_vld,

   output reg [mirror-1:0] p_srdy,
   input [mirror-1:0]      p_drdy,
   output reg [width-1:0]  p_data
   );

  reg [mirror-1:0] 	 nxt_p_srdy;
  wire                   nxt_accept;
 
  always @(posedge clk)
    if (nxt_accept)
      p_data <= `SDLIB_DELAY c_data;

  //assign c_drdy = (p_srdy == 0);
  assign c_drdy = nxt_accept;
  assign nxt_accept = (p_srdy == 0) | ((p_srdy != 0) && ((p_srdy & p_drdy) == p_srdy));

  always @*
    begin
      nxt_p_srdy = p_srdy;
      
      if (nxt_accept)
        begin
          if (c_dst_vld == {mirror{1'b0}})
            nxt_p_srdy = {mirror{c_srdy}};
          else
            nxt_p_srdy = {mirror{c_srdy}} & c_dst_vld;
        end
      else
	begin
	  nxt_p_srdy = p_srdy & ~p_drdy;
	end
    end

  always @(`SDLIB_CLOCKING)
    begin
      if (reset)
	begin
	  p_srdy   <= `SDLIB_DELAY {mirror{1'b0}};
	end
      else
	begin
	  p_srdy   <= `SDLIB_DELAY nxt_p_srdy;
	end
    end

endmodule // sd_mirror
