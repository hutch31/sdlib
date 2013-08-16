module generic_twoport
  #(parameter width=8,
    parameter data_movement=1)
  (
   input             clk,
   input             reset,

   input             c_srdy,
   input             c_drdy,
   input [width-1:0] c_data,

   input             p_srdy,
   input             p_drdy,
   input [width-1:0] p_data
  );

  //--------------------------------------------------
  // Constraints
  //--------------------------------------------------
  
  // If srdy is asserted, it should remain asserted until drdy
  property InSrdyDrdyHandshake;
    @(posedge clk) disable iff (reset)
  (c_srdy && !(c_drdy)) |-> ##1 c_srdy;
  endproperty
  InSrdyDrdyHandshake_c: assume property (InSrdyDrdyHandshake);
  
  // If srdy is asserted,
  // it should keep c_data stable untill c_drdy is recieved.
  property InSrdyDrdyDataHold;
    @(posedge clk) disable iff (reset)
    (c_srdy && !(c_drdy)) |-> ##1 (c_data == $past(c_data));
  endproperty
  InSrdyDrdyDataHold_c: assume property (InSrdyDrdyDataHold);

  generate if (data_movement == 1)
    begin : data_movement_blk
  // Srdy must be asserted at least once per 3 cycles
  property DataAvailable;
    @(posedge clk) disable iff (reset)
    (!c_srdy) |-> ##[1:2] c_srdy;
  endproperty
  DataAvailable_c : assume property (DataAvailable);
 
  // Constrain assertion of drdy to at least once per 3 cycles
  property DataDrain;
    @(posedge clk) disable iff (reset)
      (!p_drdy) |-> ##[1:2] p_drdy;
  endproperty
  DataDrain_c : assume property (DataDrain);
    end // block: data_movement_blk
  endgenerate

  //--------------------------------------------------
  // Assertions
  //--------------------------------------------------
  
  // If srdy is asserted, it should remain asserted until drdy
  property OutSrdyDrdyHandshake;
  @(posedge clk) disable iff (reset)
    (p_srdy && !(p_drdy)) |-> ##1 p_srdy;
  endproperty
  OutSrdyDrdyHandshake_a: assert property (OutSrdyDrdyHandshake);
  
  // If srdy is asserted,
  // it should keep p_data stable untill p_drdy is recieved.
  property OutSrdyDrdyDataHold;
    @(posedge clk) disable iff (reset)
    (p_srdy && !(p_drdy)) |-> ##1 (p_data == $past(p_data));
  endproperty
  OutSrdyDrdyDataHold_a: assert property (OutSrdyDrdyDataHold);

endmodule

