//----------------------------------------------------------------------
//  Linked List FIFO Control
//
// Read/Write and pointer control for LLFIFO
//
// Naming convention: c = consumer, p = producer, i = internal interface
//----------------------------------------------------------------------
//  Author: Guy Hutchison
//
// This block is uncopyrighted and released into the public domain.
//----------------------------------------------------------------------
// This is free and unencumbered software released into the public domain.
//
// Anyone is free to copy, modify, publish, use, compile, sell, or
// distribute this software, either in source code form or as a compiled
// binary, for any purpose, commercial or non-commercial, and by any
// means.
//
// In jurisdictions that recognize copyright laws, the author or authors
// of this software dedicate any and all copyright interest in the
// software to the public domain. We make this dedication for the benefit
// of the public at large and to the detriment of our heirs and
// successors. We intend this dedication to be an overt act of
// relinquishment in perpetuity of all present and future rights to this
// software under copyright law.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
// IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
// OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
// ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
// OTHER DEALINGS IN THE SOFTWARE.
//
// For more information, please refer to <http://unlicense.org/> 
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

module sd_llfifo_ctl
  #(parameter width=8,
    parameter pagesize=16,
    parameter num_pages=32,
    parameter num_queues=8,
    parameter qid_sz=$clog2(num_queues),
    parameter pid_sz=$clog2(num_pages),
    parameter mm_sz=$clog2(num_pages*pagesize))
  (
   input          clk,
   input          reset,
   input          init,

   input      c_srdy,
   output     c_drdy,
   input [qid_sz-1:0] c_qid,

   output         mm_wr_en,
   output         mm_rd_en,
   output [mm_sz-1:0] mm_addr,
   input [width-1:0]  mm_d_out,

   input [num_queues-1:0] rd_req,

/* -----\/----- EXCLUDED -----\/-----
   output         p_srdy,
   input          p_drdy,
   output [qid_sz-1:0] p_qid,
   output [width-1:0]  p_data,
 -----/\----- EXCLUDED -----/\----- */

   output reg    pv_rd,
   output reg [qid_sz-1:0] pv_qid,
/* -----\/----- EXCLUDED -----\/-----
  // free list memory
   output         flw_srdy,
   input          flw_drdy,
   output [pid_sz-1:0] flw_data,

   input          flr_srdy,
   output         flr_drdy,
   input [pid_sz-1:0] flr_data,
 -----/\----- EXCLUDED -----/\----- */

   // link memory
   input [pid_sz-1:0] lm_d_out,
   output reg lm_wr_en,
   output reg lm_rd_en,
   output reg [pid_sz-1:0] lm_d_in,
   output reg [pid_sz-1:0] lm_rd_addr,
   output reg [pid_sz-1:0] lm_wr_addr
   
   );

  localparam fdsz = $clog2(pagesize) + pid_sz + 1;
  genvar 		fid;

  reg [num_queues-1:0] 	q_drdy;
  //reg [num_queues-1:0] 	q_flr_drdy;
  reg [fdsz-1:0] 	fh_desc [0:num_queues-1];
  reg [fdsz-1:0] 	ft_desc [0:num_queues-1];
  reg [mm_sz-1:0] 	wr_addr [0:num_queues-1];
  reg [mm_sz-1:0] 	rd_addr [0:num_queues-1];
  reg [num_queues-1:0] 	wr_en, rd_en;
  reg [pid_sz-1:0] 	q_lm_wr_addr [0:num_queues-1];
  reg [pid_sz-1:0] 	q_lm_wr_data[0:num_queues-1];
  reg [pid_sz-1:0] 	q_lm_rd_addr[0:num_queues-1];
  reg [num_queues-1:0] 	q_lm_rd_en;
  reg [num_queues-1:0] 	q_lm_wr_en;
  reg 			wr_phase;
  reg [num_queues-1:0] 	grant;
  wire [$clog2(num_queues)-1:0] grant_id;
  reg [num_queues-1:0] 	       not_empty;
  reg [num_queues-1:0] 	       pp_update; // previous ll read done, update page ptr
  reg [pid_sz-1:0] 	       init_cnt, nxt_init_cnt;
  reg [pid_sz-1:0] 	       free_hptr, nxt_free_hptr;
  reg [pid_sz-1:0] 	       free_tptr, nxt_free_tptr;
  reg [$clog2(num_pages+1)-1:0] free_cnt, nxt_free_cnt;
  reg [num_queues-1:0] 		adv_free_hptr;

/* -----\/----- EXCLUDED -----\/-----
  assign lm_wr_en = |q_lm_wr_en;
  assign lm_wr_addr = q_lm_wr_addr[c_qid] ;
  assign lm_wr_data = q_lm_wr_data[c_qid];
 -----/\----- EXCLUDED -----/\----- */
  assign mm_wr_en = |wr_en;
  assign mm_rd_en = |rd_en;
  assign mm_addr = (wr_phase) ? wr_addr[c_qid] : rd_addr[grant_id];

  function [num_queues-1:0] nxt_grant;
    input [num_queues-1:0] cur_grant;
    input [num_queues-1:0] cur_req;
    reg [num_queues-1:0]   msk_req;
    reg [num_queues-1:0]   tmp_grant;
    begin
      msk_req = cur_req & ~((cur_grant - 1) | cur_grant);
      tmp_grant = msk_req & (~msk_req + 1);

      if (msk_req != 0)
        nxt_grant = tmp_grant;
      else
        nxt_grant = cur_req & (~cur_req + 1);
    end
  endfunction // if

  function [$clog2(num_queues)-1:0] encoder;
    input [num_queues-1:0] grant;
    integer 		   i;
    begin
      encoder = 0;
      for (i=0; i<grant; i=i+1)
	if (grant[i])
	  encoder = i;
    end
  endfunction

  assign grant_id = encoder (grant);
  assign c_drdy = q_drdy[c_qid];

  generate
    for (fid=0; fid<num_queues; fid=fid+1)
      begin : fhc
	wire [$clog2(pagesize)-1:0] wordptr;
	wire [pid_sz-1:0] 	    pageptr;
	wire 			    pg_valid;
	reg [$clog2(pagesize)-1:0]  nxt_wordptr;
	reg [pid_sz-1:0] 	    nxt_pageptr;
	reg 			    nxt_pg_valid;
	reg 			    full;
	

	assign {pg_valid, pageptr, wordptr} = fh_desc[fid];

	always @*
	  begin
	    q_drdy[fid] = 0;
	    //q_flr_drdy[fid] = 0;
	    nxt_wordptr = wordptr;
	    nxt_pageptr = pageptr;
	    nxt_pg_valid = pg_valid;
	    wr_addr[fid] = {pageptr,wordptr};
	    wr_en[fid]   = 0;
	    q_lm_wr_addr[fid] = pageptr;
	    q_lm_wr_data[fid] = free_hptr;
	    q_lm_wr_en[fid] = 0;
	    adv_free_hptr[fid] = 0;

	    if (c_srdy & (c_qid == fid) & wr_phase)
	      begin
		// if descriptor is invalid, start the list with a new
		// descriptor
		if (!pg_valid && (free_cnt > 0))
		  begin
		    q_drdy[fid] = 1;
		    nxt_pg_valid = 1;
		    nxt_pageptr = free_hptr;
		    nxt_wordptr = 1;
		    //q_flr_drdy[fid] = 1;
		    adv_free_hptr[fid] = 1;
		    wr_addr[fid] = { free_hptr, {$clog2(pagesize){1'b0}} };
		    wr_en[fid] = 1;
		  end
		// if we have exhausted this page, allocate a new one and
		// update the page link list
		else if (pg_valid && (free_cnt > 0) && (wordptr == (pagesize-1)))
		  begin
		    wr_en[fid] = 1;
		    nxt_pageptr = free_hptr;
		    adv_free_hptr[fid] = 1;
		    q_lm_wr_en[fid] = 1;
		    q_lm_wr_addr[fid] = pageptr;
		    q_lm_wr_data[fid] = free_hptr;
		    nxt_wordptr = 0;
		    //q_flr_drdy[fid] = 1;
		    q_drdy[fid] = 1;
		  end
		// otherwise do a regular write
		else if (pg_valid)
		  begin
		    q_drdy[fid] = 1;
		    wr_en[fid] = 1;
		    nxt_wordptr = wordptr + 1;
		  end
	      end // if (c_srdy & (c_qid == fid) & wr_phase)
	  end // always @ *

	always @(`SDLIB_CLOCKING)
	  begin
	    if (reset)
	      begin
		/*AUTORESET*/
		// Beginning of autoreset for uninitialized flops
		fh_desc[fid] <= {fdsz{1'b0}};
		// End of automatics
	      end
	    else
	      begin
		fh_desc[fid] <= `SDLIB_DELAY {nxt_pg_valid, nxt_pageptr, nxt_wordptr};
	      end
	  end
      end // block: fhc
  endgenerate

  generate
    for (fid=0; fid<num_queues; fid=fid+1)
      begin : ftc
	wire [$clog2(pagesize)-1:0] wordptr;
	wire [pid_sz-1:0] 	    pageptr;
	wire 			    pg_valid;
	reg [$clog2(pagesize)-1:0]  nxt_wordptr;
	reg [pid_sz-1:0] 	    nxt_pageptr;
	reg 			    nxt_pg_valid;

	assign {pg_valid, pageptr, wordptr} = ft_desc[fid];

	always @*
	  begin
	    not_empty[fid] = (ft_desc[fid] != fh_desc[fid]) && fhc[fid].pg_valid && pg_valid;
	    rd_addr[fid] = {pageptr, wordptr};
	    q_lm_rd_en[fid] = 0;
	    q_lm_rd_addr[fid] = pageptr;
	    nxt_pg_valid = pg_valid;
	    nxt_pageptr = pageptr;
	    nxt_wordptr = wordptr;
	    rd_en[fid] = 0;

	    if (grant[fid] & !wr_phase & pg_valid)
	      begin
		// if we are on the same page as the head descriptor, make sure we don't
		// over-read
		if ((pageptr == fhc[fid].pageptr) & (wordptr != fhc[fid].wordptr))
		  begin
		    rd_en [fid] = 1;
		    nxt_wordptr = wordptr + 1;
		  end
		// if we are on different pages, check for page rollover
		else if ((pageptr != fhc[fid].pageptr) && (wordptr == (pagesize-1)))
		  begin
		    rd_en [fid] = 1;
		    nxt_wordptr = 0;
		    q_lm_rd_en[fid] = 1;
		  end
		else if (pageptr != fhc[fid].pageptr)
		  begin
		    rd_en[fid] = 1;
		    nxt_wordptr = wordptr + 1;
		  end
		    
	      end // if (grant[fid] & !wr_phase & pg_valid)
	    else if (wr_phase)
	      begin
		if (pp_update[fid])
		  nxt_pageptr = lm_d_out;

		if (!pg_valid && fhc[fid].pg_valid)
		  begin
		    { nxt_pg_valid, nxt_pageptr, nxt_wordptr } = fh_desc[fid];
		    nxt_wordptr = 0;
		  end
	      end
	  end // always @ *

	always @(`SDLIB_CLOCKING)
	  begin
	    if (reset)
	      ft_desc[fid] <= `SDLIB_DELAY 0;
	    else
	      ft_desc[fid] <= `SDLIB_DELAY { nxt_pg_valid, nxt_pageptr, nxt_wordptr };
	  end
	      
      end // block: ftc
  endgenerate

  always @(`SDLIB_CLOCKING)
    begin
      if (reset)
	begin
	  grant <= `SDLIB_DELAY 0;
	  init_cnt <= `SDLIB_DELAY 0;
	  free_hptr <= `SDLIB_DELAY 0;
	  free_tptr <= `SDLIB_DELAY 0;
	  free_cnt <= `SDLIB_DELAY 0;
	  wr_phase <= `SDLIB_DELAY 0;
	  pv_rd <= `SDLIB_DELAY 0;
	  pv_qid <= `SDLIB_DELAY 0;
	  pp_state <= `SDLIB_DELAY 0;
	end
      else
	begin
	  init_cnt <= `SDLIB_DELAY nxt_init_cnt;
	  if (~wr_phase)
	    grant <= `SDLIB_DELAY nxt_grant (grant & not_empty, rd_req);
	  free_hptr <= `SDLIB_DELAY nxt_free_hptr;
	  free_tptr <= `SDLIB_DELAY nxt_free_tptr;
	  free_cnt <= `SDLIB_DELAY nxt_free_cnt;
	  wr_phase <= `SDLIB_DELAY ~wr_phase;
	  pv_rd <= `SDLIB_DELAY mm_rd_en;
	  if (mm_rd_en)
	    pv_qid <= `SDLIB_DELAY grant_id;
	  pp_state <= `SDLIB_DELAY nxt_pp_state;
	end
    end // always @ (`SDLIB_CLOCKING)

  always @*
    begin
      lm_wr_en = 0;
      lm_rd_en = 0;
      lm_d_in = 0;
      lm_rd_addr = 0;
      lm_wr_addr = 0;
      nxt_init_cnt = init_cnt;
      nxt_free_hptr = free_hptr;
      nxt_free_cnt = free_cnt;

      case (pp_state)
	pp_idle :
	  begin
	    if (init & (init_cnt == 0))
	      begin
		nxt_init_cnt = 1;
		nxt_pp_state = pp_init;
		lm_wr_en = 1;
		lm_rd_en = 0;
		lm_d_in = 1;
		lm_rd_addr = 0;
		lm_wr_addr = init_cnt;
		nxt_free_cnt = num_pages;
		nxt_free_hptr = 0;
	      end // if (init & (init_cnt == 0))
	    else
	      begin
		lm_wr_en = |q_lm_wr_en;
		lm_wr_addr = q_lm_wr_addr[c_qid];
		lm_d_in  = q_lm_wr_data[c_qid];
		lm_rd_en = |q_lm_rd_en;
		lm_rd_addr = q_lm_rd_addr[grant_id];
		if (|adv_free_hptr)
		  begin
		    nxt_pp_state = pp_adv_ptr;
		    lm_rd_en = 1;
		    lm_rd_addr = free_hptr;
		  end
	      end // else: !if(init_cnt != 0)

	  end // case: pp_idle

	pp_init :
	  begin
	    nxt_init_cnt = init_cnt + 1;
	    lm_wr_en = 1;
	    lm_wr_addr = init_cnt;
	    lm_d_in = init_cnt + 1;
	    if (init_cnt == (num_pages-1))
	      begin
		nxt_init_cnt = 0;
		nxt_pp_state = pp_idle;
	      end
	  end // case: pp_init

	pp_adv_ptr :
	  begin
	    //lm_wr_en = 1;
	    nxt_free_hptr = lm_rd_data;
	  end
      endcase // case (pp_state)

    end // always @ *


endmodule // sd_llfifo_ctl

