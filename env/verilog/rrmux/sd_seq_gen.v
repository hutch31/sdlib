//----------------------------------------------------------------------
// Srdy/Drdy sequence generator
//
// Simplistic traffic generator for srdy/drdy blocks.  Generates an
// incrementing data sequence.
//
// Naming convention: c = consumer, p = producer, i = internal interface
//----------------------------------------------------------------------
// Author: Guy Hutchison
//
// This block is uncopyrighted and released into the public domain.
//----------------------------------------------------------------------

// delay unit for nonblocking assigns, default is to #1
`ifndef SDLIB_DELAY 
 `define SDLIB_DELAY #1 
`endif

module sd_seq_gen
  #(parameter width=8,
    parameter tag_sz=1,
    parameter tag_val=0,
    parameter x_inval=0,
    parameter pat_dep = 8)
  
  (input clk,
   input reset,
   output reg     p_srdy,
   input          p_drdy,
   output     [width-1:0] p_data);

  reg 			  nxt_p_srdy;
  reg [width-1:0] 	  nxt_p_data;

  //parameter pat_dep = 8;
  localparam count_sz = width-tag_sz;

  reg [pat_dep-1:0] 	  srdy_pat;
  integer 		  spp, startup;
  integer 		  rep_count;
  reg [count_sz-1:0]      icount;

  initial
    begin
      srdy_pat = {pat_dep{1'b1}};
      spp = 0;
      startup = 0;
      rep_count = 0;
      icount = 0;
    end

  always @*
    begin
      nxt_p_srdy = p_srdy;

      if (p_srdy & p_drdy)
	begin

	  if (srdy_pat[spp] && (rep_count > 1))
	    begin
	      nxt_p_srdy = 1;
	    end
	  else
            begin
	      nxt_p_srdy = 0;
              if (x_inval)
                nxt_p_data = {width{1'bx}};
            end
	end // if (p_srdy & p_drdy)
      else if (!p_srdy && (rep_count != 0))
	begin
	  if (srdy_pat[spp])
	    begin
              nxt_p_data[width-1:count_sz] = tag_val;
	      nxt_p_data[count_sz-1:0] = icount;
	      nxt_p_srdy = 1;
	    end
	  else
            begin
	      nxt_p_srdy = 0;
              if (x_inval)
                nxt_p_data = {width{1'bx}};
            end
	end // if (!p_srdy && (rep_count != 0))

      if (nxt_p_srdy)
        nxt_p_data = {tag_val, icount};
      else
        nxt_p_data = {width{1'bx}};
    end // always @ *

  always @(posedge clk)
    begin
      if (reset)
        begin
          srdy_pat = {pat_dep{1'b1}};
          spp = 0;
          startup = 0;
          rep_count = 0;
        end
      else
        begin
          if ((p_srdy & p_drdy) | !p_srdy)
	    spp = (spp + 1) % pat_dep;
          
          if (p_srdy & p_drdy)
	    begin
              icount <= icount + 1;
	      if (rep_count != -1)
	        rep_count = rep_count - 1;
	    end
        end
    end

  always @(posedge clk)
    begin
      if (reset)
	begin
	  p_srdy <= `SDLIB_DELAY 0;
	  //p_data <= `SDLIB_DELAY 0;
	end
      else
	begin
	  p_srdy <= `SDLIB_DELAY nxt_p_srdy;
	  //p_data <= `SDLIB_DELAY nxt_p_data;
	end
    end // always @ (posedge clk)

  assign p_data = (x_inval & ~p_srdy) ? {width{1'bx}} : { tag_val, icount };

  // simple blocking task to send N words and then wait until complete
  task send;
    input [31:0] amount;
    begin
      rep_count = amount;
      @(posedge clk);
      while (rep_count != 0)
	@(posedge clk);
    end
  endtask

endmodule // sd_seq_gen
