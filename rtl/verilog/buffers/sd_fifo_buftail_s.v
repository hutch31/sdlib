//----------------------------------------------------------------------
// Srdy/Drdy FIFO Head "S"
//
// Building block for FIFOs.  The "S" (small/sync) FIFO is design for smaller
// FIFOs based around memories or flops, with sizes that are a power of 2.
//
// The "S" FIFO can be used as a two-clock asynchronous FIFO.
//
// Parameters:
//   depth : depth/size of FIFO, in words
//   asz   : address size, automatically computed from depth
//   async : 1 for clock-synchronization FIFO, 0 for normal
//
// The buffered tail fifo module contains a small prefetch buffer which
// it uses to match the memory latency.
//
// Naming convention: c = consumer, p = producer, i = internal interface
//----------------------------------------------------------------------
// Author: Guy Hutchison
//
// This block is uncopyrighted and released into the public domain.
//----------------------------------------------------------------------

`ifndef SD_FIFO_BUFTAIL_S_V
`define SD_FIFO_BUFTAIL_S_V
// Clocking statement for synchronous blocks.  Default is for
// posedge clocking and positive async reset
`ifdef SDLIB_ASYNC_RESET
 `define SDLIB_CLOCKING posedge clk or posedge reset
`else
 `define SDLIB_CLOCKING posedge clk
`endif

// delay unit for nonblocking assigns, default is to #1
`ifndef SDLIB_DELAY
 `define SDLIB_DELAY #1
`endif

module sd_fifo_buftail_s
  #(parameter depth=16,
    parameter width=8,
    parameter bufsize=2,
    parameter rd_lat=3,
    parameter async=0,
    parameter asz=$clog2(depth)
    )
    (
     input                  clk,
     input                  reset,

     input [asz:0]          wrptr_head,
     output reg [asz:0]     rdptr_tail,

     output reg             rd_en,
     output [asz-1:0]       rd_addr,

     input [width-1:0]      rd_data,

     output reg             p_srdy,
     input                  p_drdy,
     output reg [width-1:0] p_data,

     output reg [asz:0]     p_usage
     );

  logic                 clken;
  logic                 i_srdy, i_drdy;
  logic [width-1:0]     prefetch [0:bufsize-1];
  logic [$clog2(bufsize)-1:0] pf_hptr, pf_tptr;
  logic [$clog2(bufsize)-1:0] nxt_pf_hptr, nxt_pf_tptr;
  logic [$clog2(bufsize+1)-1:0] pfusage, nxt_pfusage;
  logic [rd_lat-1:0]            d_rd_en; // delayed read enable

  logic [asz:0]                 wrptr_head_dly;
  logic [$clog2(bufsize+1)-1:0] dyn_usage;

  function [$clog2(bufsize+1)-1:0] tot_usage;
    input [rd_lat-1:0]          d_rd_en;
    input [$clog2(bufsize+1)-1:0] pfusage;
    begin
      tot_usage = pfusage;
      for (int i=0; i<rd_lat; i++)
        tot_usage = tot_usage + d_rd_en[i];
    end
  endfunction //

  assign dyn_usage = tot_usage(d_rd_en,pfusage);
  assign clken = 1'b1;

  sd_fifo_tail_s #(/*AUTOINSTPARAM*/
                   // Parameters
                   .depth               (depth),
                   .async               (async),
                   .asz                 (asz))
    subtail
      (
       .p_srdy                          (), // replaced by usage count
       .p_drdy                          (i_drdy),
       .wrptr_head                      (wrptr_head_dly[asz:0]),
       /*AUTOINST*/
       // Outputs
       .rdptr_tail                      (rdptr_tail[asz:0]),
       .rd_en                           (rd_en),
       .rd_addr                         (rd_addr[asz-1:0]),
       .p_usage                         (p_usage[asz:0]),
       // Inputs
       .clk                             (clk),
       .clken                           (clken),
       .reset                           (reset));

  always @*
    begin
      nxt_pf_hptr = pf_hptr;
      nxt_pf_tptr = pf_tptr;
      nxt_pfusage = pfusage;

      if ((pfusage > 0) && p_drdy)
        begin
          if (pf_hptr == (bufsize-1))
            nxt_pf_hptr = 0;
          else
            nxt_pf_hptr = pf_hptr + 1;
          nxt_pfusage = pfusage - 1;
        end

      if (d_rd_en[rd_lat-1])
        begin
          //prefetch[pf_tptr] <= rd_data;
          if (pf_tptr == (bufsize-1))
            nxt_pf_tptr = 0;
          else
            nxt_pf_tptr = pf_tptr + 1;
          nxt_pfusage = nxt_pfusage + 1;
        end

      if (dyn_usage < bufsize)
        i_drdy = 1;
      else
        i_drdy = 0;
    end // always @ *

  // Static delay thrown in to avoid internal memory hazard, will make this
  // more clean & parameterized later (gth)
  always @(posedge clk)
    wrptr_head_dly <= wrptr_head;

  always @(posedge clk)
    //if (!((pfusage > 0) && p_drdy) && (d_rd_en[rd_lat-1]))
    if (d_rd_en[rd_lat-1])
      prefetch[pf_tptr] <= rd_data;

  always @(`SDLIB_CLOCKING)
    begin
      if (reset)
        begin
          pf_hptr <= 0;
          pf_tptr <= 0;
          pfusage <= 0;
          d_rd_en <= 0;
        end
      else
        begin
          pf_hptr <= nxt_pf_hptr;
          pf_tptr <= nxt_pf_tptr;
          pfusage <= nxt_pfusage;
          d_rd_en <= { d_rd_en[rd_lat-2:0], rd_en };
        end
    end // always @ (`SDLIB_CLOCKING)

  assign p_srdy = (pfusage > 0);
  assign p_data = prefetch[pf_hptr];

endmodule // sd_fifo_head_s
`endif // SD_FIFO_BUFTAIL_S_V
