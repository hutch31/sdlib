module stupid_mon
  #(parameter width = 8,
    parameter id = 0)
  (
   input        clk,
   input        reset,
   input        c_srdy,
   output reg      c_drdy,
   input [width-1:0] c_data
   );
  
  import "DPI-C" function void addDpiDriverData (input integer driverId, input integer data);
  import "DPI-C" function real getTargetRate (input integer driverId);
  real                    actualRate;

/* verilator lint_off WIDTH */  
  always @(posedge clk)
    begin
      if (reset)
        begin
          c_drdy <= 0;
          actualRate = 1.0;
        end
      else
        begin
          actualRate = actualRate * 0.95;

          if (c_srdy & c_drdy)
            begin
              actualRate += 0.05;
              addDpiDriverData (id, c_data);
            end

          if (actualRate > getTargetRate(id))
            c_drdy <= 0;
          else
            c_drdy <= 1;
          
        end
    end
/* verilator lint_on WIDTH */  

endmodule // stupid_mon
