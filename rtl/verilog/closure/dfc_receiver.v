//----------------------------------------------------------------------
// Srdy/Drdy Delayed Flow Control Receiver
//
// Converter block between srdy/drdy protocol and delayed
// flow control (system where srdy and drdy are registered).
// The delay parameter should be set to the combined
// round-trip delay of the system.
//
// The intrinsic delay of the dfc_sender and dfc_receiver is 3.
// Each additional pipeline stage of srdy or drdy adds one two
// the delay.  Note that if both srdy and drdy are registered,
// the additional delay is *2* for this stage.
//
// Parameters:
//   depth : depth/size of FIFO, in words
//   delay : threshold value to begin asserting flow control
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
//----------------------------------------------------------------------

module dfc_receiver
  #(parameter width=8,
    parameter depth=8,
    parameter threshold=3)
    (
     input              clk,
     input              reset,
     input              c_vld,
     output reg         c_fc_n,
     input [width-1:0]  c_data,

     output             p_srdy,
     input              p_drdy,
     output [width-1:0] p_data,

     output             overflow
     );

  localparam asz=$clog2(depth+1);

  /*AUTOWIRE*/
  // Beginning of automatic wires (for undeclared instantiated-module outputs)
  wire [width-1:0]      f_data;                 // From ctl of dfc_receiver_ctl.v
  wire                  f_drdy;                 // From fifo_s of sd_fifo_c.v
  wire                  f_srdy;                 // From ctl of dfc_receiver_ctl.v
  logic [asz-1:0]       f_usage;                // From fifo_s of sd_fifo_c.v
  // End of automatics

  dfc_receiver_ctl #(/*AUTOINSTPARAM*/
                     // Parameters
                     .width             (width),
                     .depth             (depth),
                     .asz               (asz),
                     .threshold         (threshold))
  ctl
    (/*AUTOINST*/
     // Outputs
     .c_fc_n                            (c_fc_n),
     .f_srdy                            (f_srdy),
     .f_data                            (f_data[width-1:0]),
     .overflow                          (overflow),
     // Inputs
     .clk                               (clk),
     .reset                             (reset),
     .c_vld                             (c_vld),
     .c_data                            (c_data[width-1:0]),
     .f_drdy                            (f_drdy),
     .f_usage                           (f_usage[asz-1:0]));
/* -----\/----- EXCLUDED -----\/-----
  reg                    l_srdy;
  wire                   l_drdy;
  reg [width-1:0]        l_data;
  wire [asz-1:0]         lcl_usage;
      
  // register inputs and outputs
  always @(posedge clk)
    begin
      if (reset)
        begin
          l_srdy <= 0;
          c_fc_n <= 0;
        end
      else
        begin
          l_srdy <= c_vld;
          c_fc_n <= (lcl_usage < threshold);
        end
    end // always @ (posedge clk)

  always @(posedge clk)
    l_data <= c_data;

  assign overflow = l_srdy & !l_drdy;
 -----/\----- EXCLUDED -----/\----- */

/* sd_fifo_c AUTO_TEMPLATE
 (
     .p_usage (),
     .usage (f_usage[]),
     .c_\(.*\)   (f_\1[]),
 );
 */
  sd_fifo_c #(.width(width), .depth(depth), .usz(asz)) fifo_s
    (/*AUTOINST*/
     // Outputs
     .c_drdy                            (f_drdy),                // Templated
     .usage                             (f_usage[asz-1:0]),      // Templated
     .p_srdy                            (p_srdy),
     .p_data                            (p_data[width-1:0]),
     // Inputs
     .clk                               (clk),
     .reset                             (reset),
     .c_srdy                            (f_srdy),                // Templated
     .c_data                            (f_data[width-1:0]),     // Templated
     .p_drdy                            (p_drdy));
  
endmodule // dfc_adapter
// Local Variables:
// verilog-library-directories:("." "../common" "../../../rtl/verilog/closure" "../../../rtl/verilog/buffers")
// End:
