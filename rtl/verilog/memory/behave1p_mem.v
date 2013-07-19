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

module behave1p_mem
  #(parameter depth=256,
    parameter width=8,
    parameter addr_sz=$clog2(depth))
  (/*AUTOARG*/
  // Outputs
  d_out,
  // Inputs
  wr_en, rd_en, clk, d_in, addr
  );
  input        wr_en, rd_en, clk;
  input [width-1:0] d_in;
  input [addr_sz-1:0]     addr;

  output [width-1:0]     d_out;

  reg [addr_sz-1:0] r_addr;

  reg [width-1:0]            array[0:depth-1];
  
  always @(posedge clk)
    begin
      if (wr_en)
        begin
          array[addr] <= #1 d_in;
        end
      else if (rd_en)
        begin
          r_addr <= #1 addr;
        end
    end // always @ (posedge clk)

  assign d_out = array[r_addr];

/* -----\/----- EXCLUDED -----\/-----
  genvar g;

  generate
    for (g=0; g<depth; g=g+1)
      begin : breakout
        wire [width-1:0] brk;

        assign brk=array[g];
      end
  endgenerate
 -----/\----- EXCLUDED -----/\----- */

endmodule
