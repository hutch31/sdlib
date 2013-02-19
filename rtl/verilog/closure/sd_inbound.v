//----------------------------------------------------------------------
// Srdy/Drdy Module Input Boundary
//
// Wrapper module for a module input boundary.
//
// If the "delay" parameter is set to a non-zero value,
// then this module instantiates an sd_iofull module to
// provide input timing closure.  For values of 2 or greater,
// it instantiates a dfc_receiver for providing delayed flow
// control support.
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

module sd_inbound
  #(parameter width=8,
    parameter depth=8,
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
      dfc_receiver #(/*AUTOINSTPARAM*/
                     // Parameters
                     .width             (width),
                     .depth             (depth),
                     .delay             (delay))
      dfc_rx
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
