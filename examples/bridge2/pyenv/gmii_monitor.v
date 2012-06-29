module gmii_monitor
  (/*AUTOARG*/
  // Inputs
  clk, reset, gmii_tx_en, gmii_txd
  );

`include "namequeue_dpi.v"  
  
  input             clk;
  input             reset;
  input             gmii_tx_en;
  input [7:0]       gmii_txd;

  parameter          depth = 2048;
  
  reg [7:0]         rxbuf [0:depth-1];
  integer           rxptr;
  integer           state;
  integer           i;
  
  parameter          st_idle = 4, st_norm = 0, st_pre = 1, st_enqueue = 2;
  
  always @(posedge clk)
    begin
      if (reset)
        begin
          state = st_idle;
          i = 1'h0;
          rxptr = 1'h0;
          // End of automatics
        end
      else
        begin
          case (state)
            st_idle :
              begin
                if (gmii_tx_en)
                  begin
                    if (gmii_txd == `GMII_SFD)
                      state = st_norm;
                    else
                      state = st_pre;
                  end
              end

            st_pre :
              begin
                if (gmii_txd == `GMII_SFD)
                  state = st_norm;
                else if (!gmii_tx_en)
                  begin
                    $display ("%t: ERROR %m: Detected packet with no SFD", $time);
                    state = st_idle;
                  end
              end
            
            st_norm :
              begin
                if (gmii_tx_en)
                  begin
                    rxbuf[rxptr  ] <= gmii_txd;
                    rxptr = rxptr + 1;
                  end
                else
                  begin
                    state = st_enqueue;
                  end
              end // case: st_norm

            st_enqueue :
              begin
                state = st_idle;
                nq_insert_open_packet ("monitor0");
                for (i=0; i<rxptr; i=i+1)
                  nq_insert_add_byte ("monitor0", rxbuf[i]);
                nq_insert_close_packet ("monitor0");
              end
          endcase // case (state)
        end
    end // always @ (posedge clk)

/* -----\/----- EXCLUDED -----\/-----
  always @(pkt_rcvd)
    begin
      #2;
      rxpkt_num = rxpkt_num + 1;
      //pid = {rxbuf[rxptr-2], rxbuf[rxptr-1]};
      
      $display ("%t: INFO    : %m: Received packet %0d length %0d", $time,rxpkt_num,rxptr);

      for (i=0; i<rxptr; i=i+1)
        begin
          if (i % 16 == 0) $write ("%x: ", i[15:0]);
          $write ("%x ", rxbuf[i]);
          if (i % 16 == 7) $write ("| ");
          if (i % 16 == 15) $write ("\n");
        end
      if (i % 16 != 0) $write ("\n");
      rxptr = 0;
    end
 -----/\----- EXCLUDED -----/\----- */
  
endmodule // it_monitor
