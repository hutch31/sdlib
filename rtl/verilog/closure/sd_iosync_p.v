//----------------------------------------------------------------------
// Srdy/Drdy Cross-Clock Synchronizer
//
// This block is the producer (receive clock domain) half of a 
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

module sd_iosync_p
  #(parameter width = 8)
  (
   input              clk,
   input              reset,

   input              s_req,
   output             s_ack,
   input [width-1:0]  s_data,

   output             p_srdy,
   input              p_drdy,
   output reg [width-1:0] p_data
   );

  localparam s_wait_req = 0, s_wait_drdy = 1, s_send_ack = 2;
  reg [2:0]               state, nxt_state;
  reg                     load;
  reg                     hgff_sync1, hgff_sync2;

  assign s_ack = state[s_send_ack];
  assign p_srdy = state[s_wait_drdy];

  always @*
    begin
      load = 0;
      nxt_state = state;
      
      case (1'b1)
        state[s_wait_req] :
          begin
            if (hgff_sync2)
              begin
                load = 1;
                nxt_state = 1 << s_send_ack;
              end
          end

        state[s_send_ack] :
          begin
            if (!s_req)
              nxt_state = 1 << s_wait_drdy;
          end

        state[s_wait_drdy] :
          begin
            if (p_drdy)
              nxt_state = 1 << s_wait_req;
          end

      endcase // case (1'b1)
    end // always @ *

  always @(posedge clk)
    begin
      if (load)
        p_data <= s_data;

      if (reset)
        state <= 1 << s_wait_req;
      else
        state <= nxt_state;

      hgff_sync1 <= s_req;
      hgff_sync2 <= hgff_sync1;
    end

endmodule // sd_iosync_p
