//----------------------------------------------------------------------
// Srdy/Drdy DDR output block
//
// Converts from SDR SDI to DDR SDI
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

module sd_out_ddr
  #(parameter width = 8)
  (
   input              clk,
   input              reset,
   input              ic_srdy,
   output reg         ic_drdy,
   input [width-1:0]  ic_data,

   output reg         p_srdy,
   input              p_drdy,
   output  [width/2-1:0] p_data
   );

  reg [width-1:0]           hold;
  reg     load;   // true when data will be loaded into p_data
  reg     nxt_p_srdy;

  always @*
    begin
      ic_drdy = p_drdy | !p_srdy;
      load  = ic_srdy & ic_drdy;
      nxt_p_srdy = load | (p_srdy & !p_drdy);
    end
  
  always @(`SDLIB_CLOCKING)
    begin
      if (reset)
        begin
          p_srdy <= `SDLIB_DELAY 0;
        end
      else
        begin
          p_srdy <= `SDLIB_DELAY nxt_p_srdy;
        end // else: !if(reset)
    end // always @ (posedge clk)

  always @(posedge clk)
    begin
      if (load)
        hold <= `SDLIB_DELAY ic_data;
      else if (~nxt_p_srdy)
        hold <= {2{ic_data[width/2-1:0]}};
    end

  assign p_data = (clk) ? hold[width-1:width/2] : hold[width/2-1:0];

endmodule // it_output
