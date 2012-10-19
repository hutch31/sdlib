//----------------------------------------------------------------------
// Srdy/Drdy DDR input block
//
// Converts DDR SDI to SDR SDI.  Also halts timing
// on all signals if the registered parameter is set.
//
// Naming convention: c = consumer, p = producer, i = internal interface
//----------------------------------------------------------------------
// Author: Guy Hutchison
//
// This block is uncopyrighted and released into the public domain.
//----------------------------------------------------------------------

// Clocking statement for synchronous blocks.  Default is for
// posedge clocking and positive async reset
`ifndef SDLIB_CLOCKING 
 `define SDLIB_CLOCKING posedge clk or posedge reset
`endif

// delay unit for nonblocking assigns, default is to #1
`ifndef SDLIB_DELAY 
 `define SDLIB_DELAY #1 
`endif

module sd_in_ddr
  #(parameter width = 8,
    parameter registered=1)
  (
   input               clk,
   input               reset,
   input               c_srdy,
   output reg          c_drdy,
   input [width/2-1:0] c_data,

   output              p_srdy,
   input               p_drdy,
   output [width-1:0]  p_data
   );

  reg                  ip_srdy;
  reg [width-1:0]      ip_data;
  reg     load;
  reg     drain;
  reg     occupied, nxt_occupied;
  reg [width-1:0] hold, nxt_hold;
  reg             nxt_c_drdy;
  reg [width/2-1:0] neg_hold;
  wire              ip_drdy;
  
  always @*
    begin
      nxt_hold = hold;
      nxt_occupied = occupied;

      drain = occupied & ip_drdy;
      load = c_srdy & c_drdy & (!ip_drdy | drain);
      if (occupied)
        ip_data = hold;
      else
        ip_data = { neg_hold, c_data };

      ip_srdy = (c_srdy & c_drdy) | occupied;

      if (load)
        begin
          nxt_hold = { neg_hold, c_data };
          nxt_occupied =  1;
        end
      else if (drain)
        nxt_occupied = 0;

      nxt_c_drdy = (!occupied & !load) | (drain & !load);
    end // always @ *

  always @(negedge clk)
    begin
      neg_hold <= c_data;
    end

  always @(`SDLIB_CLOCKING)
    begin
      if (reset)
        begin
          hold     <= `SDLIB_DELAY 0;
          occupied <= `SDLIB_DELAY 0;
          c_drdy   <= `SDLIB_DELAY 0;
        end
      else
        begin
          hold     <= `SDLIB_DELAY nxt_hold;
          occupied <= `SDLIB_DELAY nxt_occupied;
          c_drdy   <= `SDLIB_DELAY nxt_c_drdy;
        end // else: !if(reset)
    end // always @ (posedge clk)

  generate if (registered == 1)
    begin : reg_opt
      sd_output #(.width(width)) rout
        (
         .ic_drdy                       (ip_drdy),
         .p_srdy                        (p_srdy),
         .p_data                        (p_data[width-1:0]),
         // Inputs
         .clk                           (clk),
         .reset                         (reset),
         .ic_srdy                       (ip_srdy),
         .ic_data                       (ip_data[width-1:0]),
         .p_drdy                        (p_drdy));
    end
  else
    begin
      assign p_data = ip_data;
      assign p_srdy = ip_srdy;
      assign ip_drdy = p_drdy;
    end // else: !if(registered == 1)
  endgenerate
 
endmodule
