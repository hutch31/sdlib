module llmanager
  (/*AUTOARG*/
  // Outputs
  pgack, lprq_srdy, lprq_page, lnp_drdy, rlp_drdy, rlpd_srdy,
  rlpd_data, lprt_drdy, free_count,
  // Inputs
  clk, reset, pgreq, lprq_drdy, lnp_srdy, lnp_pnp, rlp_srdy,
  rlp_rd_page, rlpd_drdy, lprt_srdy, lprt_page_list
  );

  parameter lpsz = 8;    // link list page size, in bits
  parameter lpdsz = lpsz+1;  // link page data size, must be at least size of address
  parameter pages = 256; // number of pages
  //parameter sidsz = 2; // source ID size, in bits
  parameter sources = 4; // number of sources
  parameter sinks = 4;    // number of sinks
  parameter sksz = 2;     // number of sink address bits

  input clk;
  input reset;

  // page request i/f
  input [sources-1:0] pgreq;
  output [sources-1:0] pgack;

  // link page request return
  output [sources-1:0] lprq_srdy;
  input [sources-1:0] lprq_drdy;
  output [lpsz-1:0]   lprq_page;

  // link to next page i/f
  input [sources-1:0]  lnp_srdy;
  output [sources-1:0] lnp_drdy;
  input [sources*(lpsz+lpdsz)-1:0] lnp_pnp;

  // read link page i/f
  input [sinks-1:0]      rlp_srdy;
  output [sinks-1:0]     rlp_drdy;
  input [sinks*lpsz-1:0] rlp_rd_page;

  output [sinks-1:0]     rlpd_srdy;
  input [sinks-1:0]      rlpd_drdy;
  output [lpdsz-1:0]     rlpd_data;

  // link page reclaim interface
  input [sinks-1:0]   lprt_srdy;
  output [sinks-1:0]  lprt_drdy;
  input [sinks*lpsz-1:0] lprt_page_list;


  output [lpsz:0]        free_count;

  

  reg [lpsz-1:0]       r_free_head_ptr, free_tail_ptr;
  wire [lpsz-1:0]      free_head_ptr;

  reg                  pmstate;
  integer              i;
  wire [sources-1:0]   grant;
  wire                 req_srdy;

  wire reclaim_srdy;
  reg  reclaim_drdy;
  wire [lpsz-1:0] reclaim_page;

  reg [lpdsz-1:0]  pgmem_wr_data;
  reg             pgmem_wr_en;
  reg [lpsz-1:0]  pgmem_wr_addr;
  reg [lpsz-1:0]  pgmem_rd_addr;
  reg             pgmem_rd_en;
  wire [lpdsz-1:0] pgmem_rd_data;
  reg             prev_pgmem_rd;
  reg             init;
  reg [lpsz:0]    init_count;
  reg [lpsz:0]    free_count;
  wire            free_empty;
  wire            req_drdy;

  wire            irlp_srdy;
  wire            irlp_drdy;
  wire [lpsz-1:0] irlp_rd_page;
  wire [sinks-1:0] irlp_grant;

  reg             irlpd_srdy;
  wire            irlpd_drdy;
  reg [sinks-1:0] irlpd_grant, nxt_irlpd_grant;

  assign free_empty = (free_head_ptr == free_tail_ptr);
  assign free_head_ptr = (prev_pgmem_rd) ? pgmem_rd_data : r_free_head_ptr;

  sd_rrmux #(.mode(0), .fast_arb(1), 
             .width(1), .inputs(sources)) req_mux
    (
     .clk         (clk),
     .reset       (reset),

     .c_srdy      (pgreq),
     .c_drdy      (pgack),
     .c_data      ({sources{1'b0}}),
     .c_rearb     (1'b1),

     .p_srdy      (req_srdy),
     .p_drdy      (req_drdy),
     .p_data      (),
     .p_grant     (grant)
     );

  wire            ilnp_srdy;
  reg             ilnp_drdy;
  wire [lpsz-1:0] ilnp_page;
  wire [lpdsz-1:0] ilnp_nxt_page;

  sd_rrmux #(.mode(0), .fast_arb(1), 
             .width(lpsz+lpdsz), .inputs(sources)) lnp_mux
    (
     .clk         (clk),
     .reset       (reset),

     .c_srdy      (lnp_srdy),
     .c_drdy      (lnp_drdy),
     .c_data      (lnp_pnp),
     .c_rearb     (1'b1),

     .p_srdy      (ilnp_srdy),
     .p_drdy      (ilnp_drdy),
     .p_data      ({ilnp_page,ilnp_nxt_page}),
     .p_grant     ()
     );

  sd_rrmux #(.mode(0), .fast_arb(1), 
             .width(lpsz), .inputs(sources)) rlp_mux
    (
     .clk         (clk),
     .reset       (reset),

     .c_srdy      (rlp_srdy),
     .c_drdy      (rlp_drdy),
     .c_data      (rlp_rd_page),
     .c_rearb     (1'b1),

     .p_srdy      (irlp_srdy),
     .p_drdy      (irlp_drdy),
     .p_data      (irlp_rd_page),
     .p_grant     (irlp_grant)
     );

  behave2p_mem #(.depth   (pages), 
                 .addr_sz (lpsz),
                 .width   (lpdsz)) pglist_mem
    (
     .wr_clk         (clk),
     .rd_clk         (clk),

     .wr_en          (pgmem_wr_en),
     .d_in           (pgmem_wr_data),
     .wr_addr        (pgmem_wr_addr),

     .rd_en          (pgmem_rd_en),
     .rd_addr        (pgmem_rd_addr),
     .d_out          (pgmem_rd_data)
     );

  reg              load_head_ptr, nxt_load_head_ptr;
  reg              load_lp_data, nxt_load_lp_data;

  always @(posedge clk)
    begin
      if (reset)
        begin
          init <= 1;
          init_count <= 0;
          r_free_head_ptr <= 0;
          free_tail_ptr <= pages - 1;
          prev_pgmem_rd <= 0;
          free_count <= pages;
          load_head_ptr <= 0;
          load_lp_data <= 0;
          irlpd_grant <= 0;
        end
      else
        begin
          load_head_ptr <= nxt_load_head_ptr;
          load_lp_data  <= nxt_load_lp_data;
          irlpd_grant <= nxt_irlpd_grant;

          if (init)
            begin
              if (init_count < pages)
                init_count <= init_count + 1;
              else
                init <= 0;
            end
          else
            begin
              if (load_head_ptr)
                r_free_head_ptr <= pgmem_rd_data;

              if (reclaim_srdy & reclaim_drdy)
                free_tail_ptr <= reclaim_page;

              if (pgmem_rd_en & !pgmem_wr_en)
                free_count <= free_count - 1;
              else if (pgmem_wr_en & !pgmem_rd_en)
                free_count <= free_count + 1;
            end
        end // else: !if(reset)
    end // always @ (posedge clk)

  assign req_drdy = lpd_drdy & !free_empty;

  always @*
    begin
      pgmem_wr_data = 0;
      pgmem_wr_en = 0;
      pgmem_wr_addr = 0;
      pgmem_rd_addr = 0;
      pgmem_rd_en = 0;
      ilnp_drdy = 0;
      reclaim_drdy = 0;
      nxt_load_head_ptr = 0;
      nxt_load_lp_data = 0;
      nxt_irlpd_grant = irlpd_grant;

      if (init)
        begin
          pgmem_wr_en = 1;
          pgmem_wr_addr = init_count;
          pgmem_wr_data = init_count + 1;
        end
      else
        begin
          if (req_drdy & (grant != 0))
            begin
              pgmem_rd_en = 1;
              pgmem_rd_addr = free_head_ptr;
              nxt_load_head_ptr = 1;
            end
          else if (irlp_srdy & irlpd_drdy)
            begin
              pgmem_rd_en = 1;
              pgmem_rd_addr = irlp_rd_page;
              nxt_load_lp_data = 1;
              nxt_irlpd_grant = irlp_grant;
            end

          if (ilnp_srdy)
            begin
              ilnp_drdy = 1;
              pgmem_wr_en = 1;
              pgmem_wr_addr = ilnp_page;
              pgmem_wr_data = ilnp_nxt_page;
           end
          else if (reclaim_srdy)
            begin
              reclaim_drdy = 1;
              pgmem_wr_en = 1;
              pgmem_wr_addr = free_tail_ptr;
              pgmem_wr_data = reclaim_page;
            end
        end
    end

  sd_mirror #(.mirror(sources), .width(lpsz)) lp_dispatch
    (.clk   (clk),
     .reset (reset),
     
     .c_srdy (req_srdy),
     .c_drdy (lpd_drdy),
     .c_data (free_head_ptr),
     .c_dst_vld (grant),

     .p_srdy (lprq_srdy),
     .p_drdy (lprq_drdy),
     .p_data (lprq_page)
     );

  // output reflector for read link page interface
  sd_mirror #(.mirror(sinks), .width(lpdsz)) read_link_return
    (.clk   (clk),
     .reset (reset),
     
     .c_srdy (irlpd_srdy),
     .c_drdy (irlpd_drdy),
     .c_data (pgmem_rd_data),
     .c_dst_vld (irlpd_grant),

     .p_srdy (rlpd_srdy),
     .p_drdy (rlpd_drdy),
     .p_data (rlpd_data)
     );

  sd_rrmux #(.mode(0), .fast_arb(1), 
             .width(lpsz), .inputs(sinks)) reclaim_mux
    (
     .clk         (clk),
     .reset       (reset),

     .c_srdy      (lprt_srdy),
     .c_drdy      (lprt_drdy),
     .c_data      (lprt_page_list),
     .c_rearb     (1'b1),

     .p_srdy      (reclaim_srdy),
     .p_drdy      (reclaim_drdy),
     .p_data      (reclaim_page),
     .p_grant     ()
     );

endmodule // llmanager
