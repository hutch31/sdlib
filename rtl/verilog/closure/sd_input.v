//----------------------------------------------------------------------
// Author: Heeloo Chung
// Xpliant Inc. proprietary and confidential
//
// implementation base on sd_input. This version has no reset for the
// datapath (hold signal).
//
//----------------------------------------------------------------------
`ifndef _SD_INPUT_V_
`define _SD_INPUT_V_

// Clocking statement for synchronous blocks.  Default is for
// posedge clocking and positive async reset
`ifndef SDLIB_CLOCKING 
 `define SDLIB_CLOCKING posedge clk or posedge reset
`endif

// delay unit for nonblocking assigns, default is to #1
`ifndef SDLIB_DELAY 
 `define SDLIB_DELAY #1 
`endif

module sd_input
  #(parameter width = 8)
  (
   input              clk,
   input              reset,
   input              c_srdy,
   output reg         c_drdy,
   input [width-1:0]  c_data,

   output reg         ip_srdy,
   input              ip_drdy,
   output reg [width-1:0] ip_data
   );

  reg 	  load;
  reg 	  drain;
  reg 	  occupied, nxt_occupied;
  reg [width-1:0] hold, nxt_hold;
  reg 		  nxt_c_drdy;

  
  always @*
    begin
      nxt_hold = hold;
      nxt_occupied = occupied;

      drain = occupied & ip_drdy;
      load = c_srdy & c_drdy & (!ip_drdy | drain);
      if (occupied)
	ip_data = hold;
      else
	ip_data = c_data;

      ip_srdy = (c_srdy & c_drdy) | occupied;

      if (load)
	begin
	  nxt_hold = c_data;
	  nxt_occupied =  1;
	end
      else if (drain)
	nxt_occupied = 0;

      nxt_c_drdy = (!occupied & !load) | (drain & !load);
    end

  always @(`SDLIB_CLOCKING)
    begin

      hold <= `SDLIB_DELAY nxt_hold; // no reset for hold

      if (reset)
	begin
	  occupied <= `SDLIB_DELAY 0;
	  c_drdy   <= `SDLIB_DELAY 0;
	end
      else
	begin
	  occupied <= `SDLIB_DELAY nxt_occupied;
	  c_drdy   <= `SDLIB_DELAY nxt_c_drdy;
	end // else: !if(reset)
    end // always @ (posedge clk)  
 
endmodule
`endif
