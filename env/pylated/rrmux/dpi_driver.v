//----------------------------------------------------------------------
// Srdy/Drdy output block
//
// Halts timing on all signals except ic_drdy
// ic_drdy is a combinatorial path from p_drdy
//
// Naming convention: c = consumer, p = producer, i = internal interface
//----------------------------------------------------------------------
// Author: Guy Hutchison
//
// This block is uncopyrighted and released into the public domain.
//----------------------------------------------------------------------

module dpi_driver
  #(parameter width = 8, id=0)
  (
   input              clk,
   input              reset,

   output reg         p_srdy,
   input              p_drdy,
   output reg [width-1:0] p_data
   );

  import "DPI-C" function integer getDpiDriverData (input integer driverId);
  import "DPI-C" function real getTargetRate (input integer driverId);

  real                    actualRate;
  integer data;

  always @(posedge clk)
    begin
      if (reset)
        begin
          p_srdy <= 0;
          p_data <= 0;
          actualRate = 1.0;
        end
      else
        begin
          actualRate = actualRate * 0.9;
          if (p_srdy & p_drdy)
            actualRate += 0.1;
          if (~p_srdy | (p_srdy & p_drdy))
            begin
              if (actualRate > getTargetRate(id))
                p_srdy <= 0;
              else
                begin
                  data = getDpiDriverData(id);
                  if (data == -1)
                    p_srdy <= 0;
                  else
                    begin
                      p_srdy <= 1;
                      p_data <= data[width-1:0];
                    end
                end // else: !if(actualRate <= targetRate)
            end
        end // else: !if(reset)
    end // always @ (posedge clk)

endmodule
