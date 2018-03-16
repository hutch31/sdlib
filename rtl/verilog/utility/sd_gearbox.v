//----------------------------------------------------------------------
// Srdy/Drdy Gearbox
//
// Accepts input words of width "inw" and packs them into output
// words of width "outw".  Will hold data for partial words until
// additional data arrives.
//
// Can be used to serialize or deserialize data streams when inw is
// an even multiple of outw.
//
// Naming convention: c = consumer, p = producer
//----------------------------------------------------------------------
// Author: Guy Hutchison
//
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

module sd_gearbox
 #(parameter inw = 64,
   parameter outw = 40,
   parameter holdsz = (inw>outw) ? inw*2:outw*2)
 (
  input                 clk,
  input                 reset,

  input [inw-1:0]       c_data,
  input                 c_srdy,
  output reg            c_drdy,
  output reg [outw-1:0] p_data,
  output reg            p_srdy,
  input                 p_drdy
 );

  reg [$clog2(holdsz)-1:0] bheld, nxt_bheld;
  reg [holdsz-1:0] data, nxt_data;

  always @*
    begin
      c_drdy = 0;
      p_srdy = 0;
      nxt_data = data;
      nxt_bheld = bheld;
      p_data = data[outw-1:0];

      if (bheld >= outw)
        begin
          p_srdy = 1;
          if (p_drdy)
            begin
              nxt_data = data >> outw;
              nxt_bheld = bheld - outw;
            end
        end

      if (nxt_bheld < (holdsz - inw))
        begin
          c_drdy = 1;
          if (c_srdy)
            nxt_data = nxt_data | (c_data << (nxt_bheld));
        end
    end

  always @(`SDLIB_CLOCKING)
    begin
      if (reset)
        begin
          bheld <= 0;
          data <= 0;
        end
      else
        begin
          bheld <= nxt_bheld;
          data <= nxt_data;
        end
    end

endmodule

