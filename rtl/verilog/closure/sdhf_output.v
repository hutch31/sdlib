//----------------------------------------------------------------------
// Srdy/Drdy high-fanout output block
//
// High-fanout version of sd_output.  Instantiates multiple sd_output
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

// Clocking statement for synchronous blocks.  Default is for
// posedge clocking and positive async reset
`ifndef SDLIB_CLOCKING 
 `define SDLIB_CLOCKING posedge clk or posedge reset
`endif

// delay unit for nonblocking assigns, default is to #1
`ifndef SDLIB_DELAY 
 `define SDLIB_DELAY #1 
`endif

module sdhf_output
  #(parameter width = 256,
    parameter block = 32,
    parameter ctlfan = 8)
  (
   input                   clk,
   input                   reset,
   input [ctlfan-1:0]      ic_hfsrdy,
   output reg [ctlfan-1:0] ic_hfdrdy,
   input [width-1:0]       ic_data,

   output reg [ctlfan-1:0] p_hfsrdy,
   input [ctlfan-1:0]      p_hfdrdy,
   output reg [width-1:0]  p_data
   );

  genvar                   hf;

  generate for (hf=0; hf<ctlfan; hf++)
    if (hf == (ctlfan-1))
      begin : lastblock
        sd_output #(.width(width-block*(ctlfan-1))) lblock
          (
           .clk                         (clk),
           .reset                       (reset),
           // Outputs
           .ic_drdy                      (ic_hfdrdy[hf]),
           .ic_srdy                      (ic_hfsrdy[hf]),
           .ic_data                      (ic_data[width-1:block*hf]),
           // Inputs
           .p_srdy                     (p_hfsrdy[hf]),
           .p_data                     (p_data[width-1:block*hf]),
           .p_drdy                     (p_hfdrdy[hf]));
       end
    else
      begin : fanblock
        sd_output #(.width(block)) fblock
          (
           .clk                         (clk),
           .reset                       (reset),
           // Outputs
           .ic_drdy                      (ic_hfdrdy[hf]),
           .ic_srdy                      (ic_hfsrdy[hf]),
           .ic_data                      (ic_data[block*(hf+1)-1:block*hf]),
           // Inputs
           .p_srdy                     (p_hfsrdy[hf]),
           .p_data                     (p_data[block*(hf+1)-1:block*hf]),
           .p_drdy                     (p_hfdrdy[hf]));
      end
  endgenerate

endmodule // sdhf_output
//   
