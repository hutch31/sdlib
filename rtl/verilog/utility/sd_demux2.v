//----------------------------------------------------------------------
// Srdy/Drdy 2:1 Data DeMultiplexer
//
// This block converts a two half-size tokens into a full-size tokens.  The
// tokens are sent MSB first.  It is designed to communicate with a
// sd_enmux2 module.
//
// This block does not halt timing on drdy.
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

module sd_demux2
  #(parameter width=8)
  (
   input clk,
   input reset,

   input c_srdy,
   output logic c_drdy,
   input [width/2-1:0] c_data,

   output logic p_srdy,
   input p_drdy,
   output logic [width-1:0] p_data
   );

   typedef enum 	    { s_empty, s_full, s_half } state_e;
   logic [width-1:0] 	    nxt_p_data;

   state_e state, nxt_state;

   always @*
     begin
       nxt_state = state;
       nxt_p_data = p_data;
       p_srdy = 0;
       c_drdy = 0;

       case (state)
	 s_empty :
	   begin
	     c_drdy = 1;
	     if (c_srdy)
	       begin
		 nxt_p_data[width-1:width/2] = c_data;
		 nxt_state = s_half;
	       end
	   end

	 s_half :
	   begin
	     c_drdy = 1;
	     if (c_srdy)
	       begin
		 nxt_p_data[width/2-1:0] = c_data;
		 nxt_state = s_full;
	       end
	   end

	 s_full :
	   begin
	     p_srdy = 1;
	     c_drdy = p_drdy;

	     if (c_srdy & p_drdy)
	       begin
		 nxt_p_data[width-1:width/2] = c_data;
		 nxt_state = s_half;
	       end
	     else if (p_drdy)
	       nxt_state = s_empty;
	   end // case: s_full

	 default : nxt_state = s_empty;
       endcase // case (state)
     end // always @ *

   always @(posedge clk)
     begin
       if (reset)
	 state <= s_empty;
       else
	 state <= nxt_state;
     end

   always @(posedge clk)
     p_data <= nxt_p_data;
	       

endmodule // sd_demux2
