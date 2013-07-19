//----------------------------------------------------------------------
// Srdy/Drdy Module Output Boundary
//
// Wrapper module for a module input boundary.
//
// If the "delay" parameter is set to a non-zero value,
// then this module instantiates an sd_iofull module to
// provide input timing closure.  For values of 2 or greater,
// it instantiates a dfc_sender for providing delayed flow
// control support.
//
// Parameters:
//   width : datapath width
//
// Naming convention: c = consumer, p = producer, i = internal interface
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

module sd_outbound
  #(parameter width=8,
    parameter delay=0)
    (
     input       clk,
     input       reset,
     input       c_srdy,
     output reg     c_drdy,
     input [width-1:0] c_data,

     output      p_srdy,
     input       p_drdy,
     output  [width-1:0] p_data
     );

  generate if (delay == 0)
    begin : gen_iofull
      sd_iofull #(/*AUTOINSTPARAM*/
                  // Parameters
                  .width                (width))
      sd_iof
        (/*AUTOINST*/
         // Outputs
         .c_drdy                        (c_drdy),
         .p_srdy                        (p_srdy),
         .p_data                        (p_data[width-1:0]),
         // Inputs
         .clk                           (clk),
         .reset                         (reset),
         .c_srdy                        (c_srdy),
         .c_data                        (c_data[width-1:0]),
         .p_drdy                        (p_drdy));
    end
  else
    begin : gen_dfc
      dfc_sender #(/*AUTOINSTPARAM*/
                   // Parameters
                   .width               (width))
      dfc_tx
        (/*AUTOINST*/
         // Outputs
         .c_drdy                        (c_drdy),
         .p_srdy                        (p_srdy),
         .p_data                        (p_data[width-1:0]),
         // Inputs
         .clk                           (clk),
         .reset                         (reset),
         .c_srdy                        (c_srdy),
         .c_data                        (c_data[width-1:0]),
         .p_drdy                        (p_drdy));
    end
  endgenerate
  
endmodule // dfc_receiver
// Local Variables:
// verilog-library-directories:("." "../closure")
// End:
