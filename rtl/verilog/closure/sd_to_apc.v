// Conversion from srdy/drdy to async phase-change interface
// Copyright (c) 2013 Xpliant, Inc.

module sd_to_apc
  #(parameter width=32)
  (
   input                    clk,
   input                    reset,

   input                    c_srdy,
   output logic             c_drdy,
   input [width-1:0]        c_data,

   output logic             p_ph_send,
   output logic [width-1:0] p_data,
   input                    p_ph_ack
   );

  logic               vld_phase, ack_phase;
  logic               nxt_p_ph_send;
  logic [width-1:0]   nxt_p_data;
  logic               dly_ack;

  logic               state, nxt_state;

  localparam s_idle = 0, s_tx = 1;
  
  xp_synchronizer #(1) ack_sync
    (.clk (clk),
     .dataIn (p_ph_ack),
     .dataOut (sync_ph_ack));

  always @(posedge clk)
    begin
      dly_ack <= sync_ph_ack;
      p_data  <= nxt_p_data;
    end

  always @*
    begin
      nxt_p_data = p_data;
      nxt_p_ph_send = p_ph_send;
      c_drdy = 0;
      nxt_state = state;
      
      case (state)
        s_idle :
          begin
            c_drdy = 1;
            if (c_srdy)
              begin
                nxt_p_data = c_data;
                nxt_p_ph_send  = ~p_ph_send;
                nxt_state = s_tx;
              end
          end

        s_tx :
          begin
            if (dly_ack ^ sync_ph_ack)
              nxt_state = s_idle;
          end
      endcase // case (state)
    end // always @ *

  always @(posedge clk)
    begin
      if (reset)
        begin
          state <= s_idle;
          p_ph_send <= 1'b0;
        end
      else
        begin
          state <= nxt_state;
          p_ph_send <= nxt_p_ph_send;
        end
    end // always @ (posedge clk)

endmodule // sd_to_apc
