//----------------------------------------------------------------------
// Srdy/Drdy 2:1 Data Multiplexer
//
// This block converts a single token into two half-size tokens.  The
// tokens are sent MSB first.  It is designed to communicate with a
// sd_demux2 module.
//
// This block does not halt timing on drdy, and assumes its input
// module will hold data stable, which reduces the number of output
// flops required by half.  It is expected this will be paired
// with an sd_input or sd_iohalf module in front of it.
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

module sd_enmux2
  #(parameter width=8,
    parameter adj_bits=1)
  (
   input                      clk,
   input                      reset,

   input                      c_srdy,
   output logic               c_drdy,
   input [width-1:0]          c_data,

   output logic               p_srdy,
   input                      p_drdy,
   output logic [width/2-1:0] p_data
  );

   typedef enum             { s_empty, s_upper, s_lower } state_e;
   logic [width/2-1:0]      nxt_p_data;

   state_e state, nxt_state;

   // needed to break loop between enmux and demux
   assign p_srdy = (state != s_empty);

  logic [width/2-1:0]       first_cycle;
  logic [width/2-1:0]       second_cycle;       
  generate
    int                     j,k;
    if (adj_bits) begin : MUX_ADJ_BITS
    
      always @* begin
        for (int i=0; i<width/2;i=i+1) begin
          j = i*2;
          k = i*2+1;
          first_cycle[i] = c_data[k];
          second_cycle[i] = c_data[j];
        end
      end
      
    end
    else begin : MUX_MSB_LSB

      assign first_cycle  = c_data[width-1:width/2];
      assign second_cycle = c_data[width/2-1:0];
      
    end
  endgenerate
  
   always @*
     begin
       nxt_state = state;
       //p_srdy = 0;
       c_drdy = 0;
       nxt_p_data = p_data;


       case (state)
         s_empty :
           begin
             c_drdy = 0;
             if (c_srdy)
               begin
                 nxt_state = s_upper;
                 nxt_p_data = first_cycle;//c_data[width-1:width/2];
               end
           end

         s_upper :
           begin
             //p_srdy = 1;
             c_drdy = p_drdy;

             if (p_drdy)
               begin
                 nxt_state = s_lower;
                 nxt_p_data = second_cycle;//c_data[width/2-1:0];
               end
           end

         s_lower :
           begin
             c_drdy = 0;
             //p_srdy = 1;

             if (c_srdy & p_drdy)
               begin
                 nxt_state = s_upper;
                 nxt_p_data = first_cycle;//c_data[width-1:width/2];
               end
             else
               nxt_state = s_empty;
           end // case: s_lower

         default : nxt_state = s_empty;
       endcase // case (state)
     end // always @ *

   always @(posedge clk)
     begin
       if (reset)
         begin
           state <= s_empty;
         end
       else
         begin
           state <= nxt_state;
         end
     end // always @ (posedge clk)

   always @(posedge clk)
     begin
       p_data <= nxt_p_data;
     end

endmodule
