// Conversion from async phase-change interface to srdy/drdy
// Copyright (c) 2013 Xpliant, Inc.

module apc_to_sd
  #(parameter width=32)
  (
   input                    clk,
   input                    reset,

   input                    c_ph_send,
   output logic             c_ph_ack,
   input [width-1:0]        c_data,
   
   output logic             p_srdy,
   input                    p_drdy,
   output logic [width-1:0] p_data
   );

  logic                     sync_ph_send;
  logic                     dly_send;
  logic                     nxt_ph_ack;
  logic                     state, nxt_state;
  logic [width-1:0]         nxt_p_data;

  localparam s_idle = 0, s_srdy = 1;
  
  xp_synchronizer #(1) ack_sync
    (.clk (clk),
     .dataIn (c_ph_send),
     .dataOut (sync_ph_send));

  always @(posedge clk)
    begin
      dly_send <= sync_ph_send;
      p_data   <= nxt_p_data;
    end

  always @*
    begin
      p_srdy = 0;
      nxt_state = state;
      nxt_p_data = p_data;
      nxt_ph_ack = c_ph_ack;
      
      case (state)
        s_idle :
          begin
            if (dly_send ^ sync_ph_send)
              begin
                nxt_p_data = c_data;
                nxt_state  = s_srdy;
              end
          end

        s_srdy :
          begin
            p_srdy = 1;
            if (p_drdy)
              begin
                nxt_state = s_idle;
                nxt_ph_ack = ~c_ph_ack;
              end
          end

      endcase // case (state)
    end // always @ *

  always @(posedge clk)
    begin
      if (reset)
        begin
          /*AUTORESET*/
          // Beginning of autoreset for uninitialized flops
          c_ph_ack <= 1'h0;
          state <= 1'h0;
          // End of automatics
        end
      else
        begin
          state <= nxt_state;
          c_ph_ack <= nxt_ph_ack;
        end
    end
  
endmodule // apc_to_sd

