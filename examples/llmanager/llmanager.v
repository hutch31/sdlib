module llmanager
  (/*AUTOARG*/
  // Outputs
  pgack, lprq_srdy, lprq_page, lprt_drdy, free_count,
  // Inputs
  clk, reset, pgreq, lprq_drdy, lprt_srdy, lprt_page_list
  );

  parameter lpsz = 8;  // link list page size, in bits
  parameter pages = 256; // number of pages
  //parameter sidsz = 2; // source ID size, in bits
  parameter sources = 4; // number of sources
  parameter sinks = 4;    // number of sinks
  parameter sksz = 2;     // number of sink address bits

  input clk;
  input reset;

  input [sources-1:0] pgreq;
  output [sources-1:0] pgack;

  // link page request return
  output [sources-1:0] lprq_srdy;
  input [sources-1:0] lprq_drdy;
  output [lpsz-1:0]   lprq_page;

  // link page reclaim interface
  input [sinks-1:0]   lprt_srdy;
  output [sinks-1:0]  lprt_drdy;
  input [sinks*lpsz-1:0] lprt_page_list;
  output [lpsz:0]        free_count;

  

  reg [lpsz-1:0]       pglist [0:pages-1];
  reg [lpsz-1:0]       r_free_head_ptr, free_tail_ptr;
  wire [lpsz-1:0]      free_head_ptr;

  reg                  pmstate;
  integer              i;
  wire [sources-1:0]   grant;
  wire                 req_srdy;

  wire reclaim_srdy;
  wire reclaim_drdy;
  wire [lpsz-1:0] reclaim_page;
  assign reclaim_drdy = 1;

  reg [lpsz-1:0]  pgmem_wr_data;
  reg             pgmem_wr_en;
  reg [lpsz-1:0]  pgmem_wr_addr;
  reg [lpsz-1:0]  pgmem_rd_addr;
  reg             pgmem_rd_en;
  wire [lpsz-1:0] pgmem_rd_data;
  reg             prev_pgmem_rd;
  reg             init;
  reg [lpsz:0]    init_count;
  reg [lpsz:0]    free_count;
  wire            free_empty;
  wire            req_drdy;

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

  behave2p_mem #(.depth(pages), 
                 .addr_sz (lpsz),
                 .width   (lpsz)) pglist_mem
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
        end
      else
        begin
          if (init)
            begin
              if (init_count < pages)
                init_count <= init_count + 1;
              else
                init <= 0;
            end
          else
            begin
              prev_pgmem_rd <= pgmem_rd_en;
              if (prev_pgmem_rd)
                r_free_head_ptr <= pgmem_rd_data;

              if (reclaim_srdy)
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

      if (init)
        begin
          pgmem_wr_en = 1;
          pgmem_wr_addr = init_count;
          pgmem_wr_data = init_count + 1;
        end
      else
        begin
          if (req_drdy)
            begin
              if (grant != 0)
                begin
                  pgmem_rd_en = 1;
                  pgmem_rd_addr = free_head_ptr;
                end
            end

          if (reclaim_srdy)
            begin
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
