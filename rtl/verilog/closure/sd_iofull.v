//----------------------------------------------------------------------
// Srdy/Drdy input/output block
//
// Halts timing on all signals with efficiency of 1.0.  Note that this
// block is simply a combination of sd_input and sd_output.
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

module sd_iofull
  #(parameter width = 8,
    parameter isinput = 0)
  (
   input              clk,
   input              reset,
   input              c_srdy,
   output             c_drdy,
   input [width-1:0]  c_data,

   output             p_srdy,
   input              p_drdy,
   output [width-1:0] p_data
   );

  wire                i_drdy;
  wire [width-1:0]    i_data;
  wire                i_srdy;

  generate if (isinput == 1)
    begin : input_config
      sd_output #(.width(width)) in
        (
         .ic_drdy                           (c_drdy),
         .p_srdy                            (i_srdy),
         .p_data                            (i_data),
         .clk                               (clk),
         .reset                             (reset),
         .ic_srdy                           (c_srdy),
         .ic_data                           (c_data),
         .p_drdy                            (i_drdy));

      sd_input #(.width(width)) out
        (
         .c_drdy                            (i_drdy),
         .ip_srdy                           (p_srdy),
         .ip_data                           (p_data),
         .clk                               (clk),
         .reset                             (reset),
         .c_srdy                            (i_srdy),
         .c_data                            (i_data),
         .ip_drdy                           (p_drdy));
    end
  else
    begin : output_config
      sd_input #(.width(width)) in
        (
         .c_drdy                            (c_drdy),
         .ip_srdy                           (i_srdy),
         .ip_data                           (i_data),
         .clk                               (clk),
         .reset                             (reset),
         .c_srdy                            (c_srdy),
         .c_data                            (c_data),
         .ip_drdy                           (i_drdy));
      
      sd_output #(.width(width)) out
        (
         .ic_drdy                           (i_drdy),
         .p_srdy                            (p_srdy),
         .p_data                            (p_data),
         .clk                               (clk),
         .reset                             (reset),
         .ic_srdy                           (i_srdy),
         .ic_data                           (i_data),
         .p_drdy                            (p_drdy));
    end // block: output_config
  endgenerate
    
endmodule
