//----------------------------------------------------------------------
// Srdy/Drdy Cross-Clock Synchronizer
//
// This block is the consumer (sending clock domain) half of a 
// clock domain crossing.
// This block is intended for low data rates, for higher rates use
// the sd_fifo_s component.
//
// Block uses a four-way handshake to make sure both sides are ready
// to continue and that data was received.  If clock speeds are equal
// this block can accept one data unit per 11 clocks.
//
// All synchronizer flops start with "hgff" for replacement during
// synthesis with high-gain flops.
//
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

module sd_iosync_c
  #(parameter width = 8)
  (
   input              clk,
   input              reset,
   input              c_srdy,
   output             c_drdy,
   input [width-1:0]  c_data,

   output             s_req,
   input              s_ack,
   output reg [width-1:0] s_data
   );

  localparam s_wait_data = 0, s_send_req = 1, s_wait_clear = 2;
  reg [2:0]               state, nxt_state;
  reg                     load;
  reg                     hgff_sync1, hgff_sync2;
  
  assign s_req = state[s_send_req];
  assign c_drdy = state[s_wait_data];

  always @*
    begin
      nxt_state = state;
      load = 0;
      
      case (1'b1)
        state[s_wait_data] :
          begin
            if (c_srdy)
              begin
                nxt_state = 1 << s_send_req;
                load = 1;
              end
          end

        state[s_send_req] :
          begin
            if (hgff_sync2)
              nxt_state = 1 << s_wait_clear;
          end

        state[s_wait_clear] :
          begin
            if (!hgff_sync2)
              nxt_state = 1 << s_wait_data;
          end
      endcase // case (1'b1)
    end // always @ *

  always @(posedge clk)
    begin
      if (load)
        s_data <= c_data;
      
      if (reset)
        state <= 1 << s_wait_data;
      else
        state <= nxt_state;

      hgff_sync1 <= s_ack;
      hgff_sync2 <= hgff_sync1;
    end
      
  

endmodule // it_output
