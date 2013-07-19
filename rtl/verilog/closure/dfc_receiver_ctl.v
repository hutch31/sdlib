//----------------------------------------------------------------------
// Srdy/Drdy Delayed Flow Control Receiver
//
// Converter block between srdy/drdy protocol and delayed
// flow control (system where srdy and drdy are registered).
// The delay parameter should be set to the combined
// round-trip delay of the system.
//
// The size of the receive FIFO should be (round trip delay + threshold)
// words.
//
// Parameters:
//   depth : depth/size of FIFO, in words
//   threshold : threshold value to begin asserting flow control
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

module dfc_receiver_ctl
  #(parameter width=8,
    parameter depth=8,
    parameter asz=$clog2(depth+1),
    parameter threshold=1)
    (
     input                    clk,
     input                    reset,
     input                    c_vld,
     output                   c_fc_n,
     input [width-1:0]        c_data,

     // Fifo read/write control
     output logic             f_srdy,
     input                    f_drdy,
     output logic [width-1:0] f_data,
     input [asz-1:0]          f_usage,

     output                   overflow
     );

  assign c_fc_n = f_usage < threshold;
  
  // register inputs and outputs
  always @(posedge clk)
    begin
      if (reset)
        begin
          f_srdy <= 0;
        end
      else
        begin
          f_srdy <= c_vld;
        end
    end // always @ (posedge clk)

  always @(posedge clk)
    f_data <= c_data;

  assign overflow = f_srdy & !f_drdy;
  
endmodule
// Local Variables:
// verilog-library-directories:("." "../common" "../../../rtl/verilog/closure" "../../../rtl/verilog/buffers")
// End:
