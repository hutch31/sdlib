//----------------------------------------------------------------------
//  Srdy/drdy assymetric join
//
//  Performs assymetric join of 2 inputs by concatination.  Efficiency
//  of 0.5.
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

module sd_ajoin2
  #(parameter c1_width=8,
    parameter c2_width=8)
  (
   input              clk,
   input              reset,
  
   input              c1_srdy,
   output             c1_drdy,
   input [c1_width-1:0] c1_data,

   input              c2_srdy,
   output             c2_drdy,
   input [c2_width-1:0] c2_data,
  
   output             p_srdy,
  
   input              p_drdy,
   output reg [c1_width+c2_width-1:0] p_data
   );
  reg [c1_width+c2_width-1:0]    nxt_p_data;

  reg [1:0]          in_drdy, nxt_in_drdy;

  assign             {c2_drdy,c1_drdy} = in_drdy;

  always @*
    begin
      nxt_p_data = p_data;
      nxt_in_drdy = in_drdy;
      
      if (in_drdy[0])
        begin
          if (c1_srdy)
            begin
              nxt_in_drdy[0] = 0;
              nxt_p_data[c1_width-1:0] = c1_data;
            end
        end
      else if (p_srdy & p_drdy)
        nxt_in_drdy[0] = 1;

      if (in_drdy[1])
        begin
          if (c2_srdy)
            begin
              nxt_in_drdy[1] = 0;
              nxt_p_data[c2_width+c1_width-1:c1_width] = c2_data;
            end
        end
      else if (p_srdy & p_drdy)
        nxt_in_drdy[1] = 1;
    end
  
  always @(`SDLIB_CLOCKING)
    begin
      if (reset)
	begin
          in_drdy  <= `SDLIB_DELAY 2'b11;
	  p_data <= `SDLIB_DELAY 0;
	end
      else
	begin
          in_drdy  <= `SDLIB_DELAY nxt_in_drdy;
          p_data <= `SDLIB_DELAY nxt_p_data;
	end // else: !if(reset)
    end // always @ (posedge clk)

  assign p_srdy = & (~in_drdy);
	  
endmodule // it_output
