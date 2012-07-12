// Send an ethernet packet over GMII

module gmii_driver
  #(parameter id="driver0")
  (
   input            rx_clk,
   input            reset,
   output reg [7:0] rxd,
   output reg       rx_dv);

  reg [3:0]         state;
  reg [7:0]         pktbuf [0:2048];
  reg [31:0]        crc32_result;
  reg [15:0]        pkt_len, pkt_ptr;

`include "namequeue_dpi.v"

  localparam s_idle = 0, s_transmit = 1;

  task get_packet;
    integer i;
    
    begin
      if (nq_queue_empty(id) != 0)
        begin
          nq_get_open_packet(id);
          pkt_len = nq_get_length_packet(id);
          pkt_ptr <= 0;

          for (i=0; i<pkt_len; i=i+1)
            pktbuf[i] = nq_get_byte_packet(id);
          nq_get_close_packet(id);
        end
    end
  endtask
          
  task gencrc32;
    input [7:0]   length;
    output [31:0] icrc;
    reg [31:0]    nxt_icrc;
    integer       i, len;
    begin
      icrc = {32{1'b1}};
      
      for (len=0; len<length; len=len+1)
        begin
          nxt_icrc[7:0] = icrc[7:0] ^ pktbuf[len];
          nxt_icrc[31:8] = icrc[31:8];

          for (i=0; i<8; i=i+1)
            begin
              if (nxt_icrc[0])
                nxt_icrc = nxt_icrc[31:1] ^ 32'hEDB88320;
              else
                nxt_icrc = nxt_icrc[31:1];
            end

          icrc = nxt_icrc;
          //$display ("DEBUG: byte %02d data=%x crc=%x", len, pktbuf[len], icrc);
        end // for (len=0; len<length; len=len+1)

      icrc = ~icrc;
    end
  endtask
      
/* -----\/----- EXCLUDED -----\/-----
  // Copied from: http://www.mindspring.com/~tcoonan/gencrc.v
  // 
  // Generate a (DOCSIS) CRC32.
  //
  // Uses the GLOBAL variables:
  //
  //    Globals referenced:
  //       parameter    CRC32_POLY = 32'h04C11DB7;
  //       reg [ 7:0]   crc32_packet[0:255];
  //       integer      crc32_length;
  //
  //    Globals modified:
  //       reg [31:0]   crc32_result;
  //
  localparam    CRC32_POLY = 32'h04C11DB7;
  task gencrc32;
    input [31:09] crc32_length;
    integer     cbyte, cbit;
    reg         msb;
    reg [7:0]   current_cbyte;
    reg [31:0]  temp;
    begin
      crc32_result = 32'hffffffff;
      for (cbyte = 0; cbyte < crc32_length; cbyte = cbyte + 1) begin
        current_cbyte = rxbuf[cbyte];
         for (cbit = 0; cbit < 8; cbit = cbit + 1) begin
            msb = crc32_result[31];
            crc32_result = crc32_result << 1;
            if (msb != current_cbyte[cbit]) begin
               crc32_result = crc32_result ^ CRC32_POLY;
               crc32_result[0] = 1;
            end
         end
      end
      
      // Last step is to "mirror" every bit, swap the 4 bytes, and then complement each bit.
      //
      // Mirror:
      for (cbit = 0; cbit < 32; cbit = cbit + 1)
         temp[31-cbit] = crc32_result[cbit];
         
      // Swap and Complement:
      crc32_result = ~{temp[7:0], temp[15:8], temp[23:16], temp[31:24]};
   end
endtask
 -----/\----- EXCLUDED -----/\----- */

  task print_packet;
    input [31:0] length;
    integer      i;
    begin
      for (i=0; i<length; i=i+1)
        begin
          if (i % 16 == 0) $write ("%x: ", i[15:0]);
          $write ("%x ", pktbuf[i]);
          if (i % 16 == 7) $write ("| ");
          if (i % 16 == 15) $write ("\n");
        end
      if (i % 16 != 0) $write ("\n");
    end
  endtask

  always @(posedge rx_clk)
    begin
      if (reset)
        begin
          pkt_len = 0;
          /*AUTORESET*/
          // Beginning of autoreset for uninitialized flops
          pkt_ptr <= 16'h0;
          rx_dv <= 1'h0;
          rxd <= 8'h0;
          state <= 4'h0;
          // End of automatics
        end
      else
        begin
          if (state == s_idle)
            begin
              get_packet();
              if (pkt_len != 0)
                state <= s_transmit;
            end
          else if (state == s_transmit)
            begin
              if (pkt_ptr == pkt_len)
                begin
                  rx_dv <= 0;
                  state <= s_idle;
                end
              else
                begin                  
                  rx_dv <= 1;
                  rxd   <= pktbuf[pkt_ptr];
                  pkt_ptr <= pkt_ptr + 1;
                end
            end
        end
    end
      
endmodule // gmii_driver
