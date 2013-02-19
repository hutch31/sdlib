//----------------------------------------------------------------------
// Srdy/Drdy Delayed Flow Control Sender
//
// Converter block between srdy/drdy protocol and delayed
// flow control (system where srdy and drdy are registered).
// The delay parameter should be set to the combined
// round-trip delay of the system.
//
// Naming convention: c = consumer, p = producer, i = internal interface
//----------------------------------------------------------------------
// Author: Guy Hutchison
//
// This block is uncopyrighted and released into the public domain.
//----------------------------------------------------------------------
module dfc_sender
  #(parameter width=8)
    (
     input       clk,
     input       reset,
     input       c_srdy,
     output      c_drdy,
     input [width-1:0] c_data,

     output reg     p_srdy,
     input          p_drdy,
     output reg [width-1:0] p_data
     );

  reg                       fc_active;

  always @(posedge clk)
    begin
      if (reset)
        begin
          fc_active <= 1;
          p_srdy    <= 0;
        end
      else
        begin
          if (fc_active & p_drdy)
            fc_active <= 0;
          else if (!fc_active & !p_drdy)
            fc_active <= 1;

          if (c_srdy & !fc_active)
              p_srdy <= 1;
          else
              p_srdy <= 0;
        end // else: !if(reset)
    end // always @ (posedge clk)

  always @(posedge clk)
    begin
      if (c_srdy & !fc_active)
        p_data <= c_data;
    end

  assign c_drdy = !fc_active;

endmodule // dfc_adapter

