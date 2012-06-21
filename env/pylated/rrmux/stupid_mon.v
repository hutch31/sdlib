module stupid_mon
  #(parameter width = 8)
  (
   input        clk,
   input        reset,
   input        c_srdy,
   output       c_drdy,
   input [width-1:0] c_data
   );
  
  always @(posedge clk)
    begin
      if (c_srdy)
        $display ("Rcv data: %x", c_data);
    end
  assign c_drdy = 1;

endmodule // stupid_mon
