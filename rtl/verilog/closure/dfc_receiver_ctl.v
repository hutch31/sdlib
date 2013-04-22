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
// This block is uncopyrighted and released into the public domain.
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
