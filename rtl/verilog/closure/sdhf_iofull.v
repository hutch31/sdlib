//----------------------------------------------------------------------
// Srdy/Drdy high-fanout iofull block
//
// High-fanout version of sd_iofull.  Instantiates multiple sd_output
// blocks in parallel.  Block is the number of bits going to each
// sd_output block.  Width is total width; it does not need to be
// a multiple of block size, but must meet:
//    width > (ctlfan-1)*block+1
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

module sdhf_iofull
  #(parameter width = 256,
    parameter block = 32,
    parameter ctlfan = 8,
    parameter isinput = 0)
  (
   input                   clk,
   input                   reset,
   input [ctlfan-1:0]      c_hfsrdy,
   output reg [ctlfan-1:0] c_hfdrdy,
   input [width-1:0]       c_data,

   output reg [ctlfan-1:0] p_hfsrdy,
   input [ctlfan-1:0]      p_hfdrdy,
   output reg [width-1:0]  p_data
   );
   
  logic [ctlfan-1:0]   i_hfsrdy, i_hfdrdy;
  logic [width-1:0]    i_data;

  generate if (isinput == 1)
    begin : input_type
      sdhf_output #(.width(width), .block(block), .ctlfan(ctlfan)) in
        (
         .clk                               (clk),
         .reset                             (reset),
         
         .ic_hfsrdy                           (c_hfsrdy),
         .ic_hfdrdy                           (c_hfdrdy),
         .ic_data                           (c_data),
         
         .p_hfsrdy                            (i_hfsrdy),
         .p_hfdrdy                            (i_hfdrdy),
         .p_data                            (i_data)

         );

        
      sdhf_input #(.width(width), .block(block), .ctlfan(ctlfan)) out
        (
         .clk                               (clk),
         .reset                             (reset),
        
         .c_hfsrdy                            (i_hfsrdy),
         .c_hfdrdy                            (i_hfdrdy),
         .c_data                            (i_data),
         
         .ip_hfsrdy                           (p_hfsrdy),
         .ip_hfdrdy                           (p_hfdrdy),
         .ip_data                           (p_data)
         );
    end // block: input_type
  else
    begin : output_type
      sdhf_input #(.width(width), .block(block), .ctlfan(ctlfan)) in
        (
         .clk                               (clk),
         .reset                             (reset),
        
         .c_hfsrdy                            (c_hfsrdy),        
         .c_hfdrdy                            (c_hfdrdy),
         .c_data                            (c_data),
         
         .ip_hfsrdy                           (i_hfsrdy),
         .ip_hfdrdy                           (i_hfdrdy),
         
         .ip_data                           (i_data)
         );


      
      sdhf_output #(.width(width), .block(block), .ctlfan(ctlfan)) out
        (
         .clk                               (clk),
         .reset                             (reset),
        
         .ic_hfsrdy                           (i_hfsrdy),
        
         .ic_hfdrdy                           (i_hfdrdy),
         .ic_data                           (i_data),
         
         .p_hfsrdy                            (p_hfsrdy),
         .p_hfdrdy                            (p_hfdrdy),         
         .p_data                            (p_data)
         );
        
    end // block: output_type
  endgenerate
    
endmodule
