module allocator
  (
   input         clk,
   input         reset,

   input	       	crx_abort,
   input       		crx_commit,
   input [`PFW_SZ-1:0]	crx_data,
   output reg		crx_drdy,
   input		crx_srdy,

   // page request i/f
   output            par_srdy,
   input             par_drdy,

   input             parr_srdy,
   output            parr_drdy,
   input [`LL_PG_ASZ-1:0]  parr_page,

   // link to next page i/f
   output reg        lnp_srdy,
   input             lnp_drdy,
   output reg [`LL_LNP_SZ-1:0] lnp_pnp,

   // interface to packet buffer
   output [`PBR_SZ-1:0] pbra_data,
   output               pbra_srdy,
   input                pbra_drdy,

   output [`LL_PG_ASZ-1:0] a2f_start,
   output [`LL_PG_ASZ-1:0] a2f_end,
   output reg              a2f_srdy,
   input                   a2f_drdy
   );

  reg [2:0]                pcount;
  reg [1:0]                word_count;
  reg [`LL_PG_ASZ-1:0]     start_pg;
  reg [`LL_PG_ASZ-1:0]     cur_pg;
  reg [`LL_PG_ASZ-1:0]     nxt_start_pg;
  reg [`LL_PG_ASZ-1:0]     nxt_cur_pg;

  reg                      obuf_srdy;
  wire [`PB_ASZ-1:0]       obuf_addr;
  reg [1:0]                cur_line, nxt_cur_line;
  wire                     obuf_drdy;

  wire [`PBR_SZ-1:0]       obuf_pbr_word;

  wire                     pp_srdy;
  reg                      pp_drdy;
  wire [`LL_PG_ASZ-1:0]    pp_page;

  assign obuf_addr = { cur_pg, cur_line };

  //------------------------------------------------------------
  // page prefetch FIFO and state machine logic
  //------------------------------------------------------------

  wire                     pcount_inc = par_srdy & par_drdy;
  wire                     pcount_dec = pp_srdy & pp_drdy;
  assign par_srdy = (pcount < 4);

  always @(posedge clk)
    begin
      if (reset)
        pcount <= 0;
      else
        begin
          if (pcount_inc & !pcount_dec)
            pcount <= pcount + 1;
          else if (pcount_dec & !pcount_inc)
            pcount <= pcount - 1;
        end
    end

  sd_fifo_s #(.width(`LL_PG_ASZ), .depth(4)) page_prefetch
    (
     .c_clk      (clk),
     .c_reset    (reset),
     .p_clk      (clk),
     .p_reset    (reset),

     .c_srdy   (parr_srdy),
     .c_drdy   (parr_drdy),
     .c_data   (parr_page),

     .p_srdy   (pp_srdy),
     .p_drdy   (pp_drdy),
     .p_data   (pp_page));

  always @(posedge clk)
    begin
      if (pp_srdy & pp_drdy)
        $display ("%t %m: Storing in page %0d", $time, pp_page);
      if (crx_srdy & crx_drdy & crx_commit)
        $display ("%t %m: Sent packet (%0d,%0d)", $time, start_pg, cur_pg);
    end

  //------------------------------------------------------------
  // 
  //------------------------------------------------------------

  assign a2f_start = start_pg;
  assign a2f_end   = cur_pg;

  reg [2:0] state, nxt_state;
  localparam s_idle = 0, s_noalloc = 1, s_link = 2, s_commit = 3,
    s_abort = 4, s_commit2 = 5;

  always @*
    begin
      crx_drdy = 0;
      obuf_srdy = 0;
      lnp_srdy = 0;
      nxt_start_pg = start_pg;
      nxt_cur_pg = cur_pg;
      nxt_cur_line = cur_line;
      lnp_pnp = { cur_pg, 1'b0, pp_page };
      a2f_srdy = 0;
      pp_drdy = 0;

      case (state)
        s_idle :
          begin
            // if output buffer is ready and a page is allocated,
            // preload the address counters to get ready for a packet
            if (pp_srdy)
              begin
                nxt_start_pg = pp_page;
                nxt_cur_pg   = pp_page;
                nxt_cur_line = 0;
                nxt_state = s_noalloc;
                pp_drdy = 1;
              end
          end // case: s_idle

        s_noalloc :
          begin
            if (crx_srdy & obuf_drdy)
              begin
                crx_drdy = 1;
                obuf_srdy = 1;
                nxt_cur_line = cur_line + 1;
                if (`ANY_EOP(crx_data[`PRW_PCC]))
                  begin
                    if (crx_commit)
                      nxt_state = s_commit;
                    else
                      nxt_state = s_abort;
                  end
                else if (cur_line == 3)
                  begin
                    nxt_state = s_link;
                  end
              end // if (crx_srdy & obuf_drdy)
          end // case: s_noalloc


        s_link :
          begin
            if (pp_srdy)
              begin
                lnp_srdy = 1;
                if (lnp_drdy)
                  begin
                    nxt_cur_pg = pp_page;
                    pp_drdy = 1;
                    nxt_state = s_noalloc;
                  end
              end   
          end // case: s_link

        s_commit :
          begin
            lnp_pnp = { cur_pg, `LL_ENDPAGE };
            lnp_srdy = 1;
            if (lnp_drdy)
              nxt_state = s_commit2;
          end

        s_commit2 :
          begin
            a2f_srdy = 1;
            if (a2f_drdy)
              nxt_state = s_idle;
          end

        s_abort :
          begin
            // need to reclaim pages here
          end

        default : nxt_state = s_idle;
      endcase // case (state)
    end
        
  always @(posedge clk)
    begin
      if (reset)
        begin
          state <= s_idle;
          /*AUTORESET*/
          // Beginning of autoreset for uninitialized flops
          cur_line <= 2'h0;
          cur_pg <= {(1+(`LL_PG_ASZ-1)){1'b0}};
          start_pg <= {(1+(`LL_PG_ASZ-1)){1'b0}};
          // End of automatics
        end
      else
        begin
          start_pg <= nxt_start_pg;
          cur_pg   <= nxt_cur_pg;
          cur_line <= nxt_cur_line;
          state    <= nxt_state;
        end
    end

  assign obuf_pbr_word[`PBR_DATA] = crx_data;
  assign obuf_pbr_word[`PBR_ADDR] = obuf_addr;
  assign obuf_pbr_word[`PBR_WRITE] = 1'b1;
  assign obuf_pbr_word[`PBR_PORT]  = 0;

  sd_iohalf #(.width(`PBR_SZ)) obuf
    (.clk (clk), .reset (reset),

     .c_srdy (obuf_srdy),
     .c_drdy (obuf_drdy),
     .c_data (obuf_pbr_word),

     .p_srdy (pbra_srdy),
     .p_drdy (pbra_drdy),
     .p_data (pbra_data));
            
endmodule // allocator

