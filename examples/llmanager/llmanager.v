module llmanager
  (/*AUTOARG*/
  // Outputs
  pgack, lprq_srdy, lprq_page, lprt_drdy,
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
  reg [sources-1:0] pgack;

  // link page request return
  output [sources-1:0] lprq_srdy;
  input [sources-1:0] lprq_drdy;
  output [lpsz-1:0]   lprq_page;

  // link page reclaim interface
  input [sinks-1:0]   lprt_srdy;
  output [sinks-1:0]  lprt_drdy;
  input [sinks*lpsz-1:0] lprt_page_list;

  

  reg [lpsz-1:0]       pglist [0:pages-1];
  reg [lpsz-1:0]       free_head_ptr, free_tail_ptr;

  reg                  pmstate;
  integer              i;
  reg [sources-1:0]    grant;


  function [sources-1:0] nxt_grant;
    input [sources-1:0] cur_grant;
    input [sources-1:0] cur_req;
    reg [sources-1:0]   msk_req;
    reg [sources-1:0]   tmp_grant;
    begin
      msk_req = cur_req & ~((cur_grant - 1) | cur_grant);
      tmp_grant = msk_req & (~msk_req + 1);

      if (msk_req != 0)
        nxt_grant = tmp_grant;
      else
        nxt_grant = cur_req & (~cur_req + 1);
    end
  endfunction // if

  initial
    begin
      for (i=0; i<pages; i=i+1)
        pglist[i] = i+1;
      free_head_ptr = 0;
      free_tail_ptr = 255;
      pgack = 0;
    end

  wire reclaim_srdy;
  wire reclaim_drdy;
  wire [lpsz-1:0] reclaim_page;
  assign reclaim_drdy = 1;

  always
    begin
      @(posedge clk);
      if ((free_head_ptr != free_tail_ptr) & lpd_drdy)
        begin
          grant = nxt_grant (pgack, pgreq);
          pgack <= grant;
          if (grant != 0)
            free_head_ptr <= pglist[free_head_ptr];
        end
      else
        grant = 0;

      if (reclaim_srdy)
        begin
          pglist[free_tail_ptr] <= reclaim_page;
          free_tail_ptr <= reclaim_page;
        end
    end // always begin

  sd_mirror #(.mirror(sources), .width(lpsz)) lp_dispatch
    (.clk   (clk),
     .reset (reset),
     
     .c_srdy (|grant),
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
