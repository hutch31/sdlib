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
// This block is uncopyrighted and released into the public domain.
//----------------------------------------------------------------------

module dfc_receiver
  #(parameter width=8,
    parameter depth=8,
    parameter delay=3)
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

  localparam asz=$clog2(depth+1);

  reg                    l_srdy;
  reg                    l_drdy;
  reg [width-1:0]        l_data;
  wire [asz-1:0]         lcl_usage;
      
  // register inputs and outputs
  always @(posedge clk)
    begin
      if (reset)
        begin
          l_srdy <= 0;
          c_drdy <= 0;
        end
      else
        begin
          l_srdy <= c_srdy;
          c_drdy <= (lcl_usage < delay);
        end
    end // always @ (posedge clk)

  always @(posedge clk)
    l_data <= c_data;

/* sd_fifo_c AUTO_TEMPLATE
 (
     .p_usage (),
     .usage (lcl_usage),
     .c_drdy (),
     .c_\(.*\)   (l_\1[]),
 );
 */
  sd_fifo_c #(.width(width), .depth(depth)) fifo_s
    (/*AUTOINST*/
     // Outputs
     .c_drdy                            (),                      // Templated
     .usage                             (lcl_usage),             // Templated
     .p_srdy                            (p_srdy),
     .p_data                            (p_data[(width)-1:0]),
     // Inputs
     .clk                               (clk),
     .reset                             (reset),
     .c_srdy                            (l_srdy),                // Templated
     .c_data                            (l_data[(width)-1:0]),   // Templated
     .p_drdy                            (p_drdy));
  
endmodule // dfc_adapter
// Local Variables:
// verilog-library-directories:("." "../common" "../../../rtl/verilog/closure" "../../../rtl/verilog/buffers")
// End:
