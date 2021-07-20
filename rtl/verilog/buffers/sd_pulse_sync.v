/*
 * Pulse Synchronizer
 * 
 * Converts a single-cycle pulse from the in clock domain to a single-cycle pulse on
 * the out clock domain.  Requires that pulses be farther apart than roughly 4 clock
 * cycles of the slower domain.
 */

module sd_pulse_sync
  (
   input clk_in,
   input reset_in,
   input pulse_in,

   input clk_out,
   input reset_out,
   output pulse_out
   );

  reg     r_pulse_in;

  always @(posedge clk_in)
    begin
      if (reset_in)
        r_pulse_in <= 1'b0;
      else if (pulse_in)
        r_pulse_in <= 1'b1;
      else if (ack_in)
        r_pulse_in <= 1'b0;
    end

  sd_sync2 #(.width(1)) sync_in2out
    (.clk (clk_out),
     .sync_in (r_pulse_in),
     .sync_out (s_pulse_out)
     );

  sd_sync2 #(.width(1)) sync_out2in
    (.clk (clk_in),
     .sync_in  (s_pulse_out),
     .sync_out (ack_in)
     );

  reg d_pulse_out;

  always @(posedge clk_out)
    begin
      if (reset_out)
        d_pulse_out <= 1'b0;
      else
        d_pulse_out <= s_pulse_out;
    end

  assign pulse_out = s_pulse_out & !d_pulse_out;
  
endmodule // sd_pulse_sync
