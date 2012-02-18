//----------------------------------------------------------------------
//  Generic Irdy/Trdy FIFO
//----------------------------------------------------------------------
//  Author: Guy Hutchison
//
//  Copyright (c) 2005 D5 Networks
//  All Rights Reserved
//----------------------------------------------------------------------

module it_fifo
  #(parameter width=8,
    parameter depth=16,
    parameter asz=4,
    parameter npt=0      // Non-power of two
    )
    (
     input       clk,
     input       reset,
     input       irdy_in,
     output      trdy_in,
     input [width-1:0] data_in,

     output            irdy_out,
     input             trdy_out,
     output [width-1:0] data_out
     );

  reg [width-1:0] 	mem [0:depth-1];
  reg [asz:0] 		wrptr, rdptr;
  reg [asz:0] 		nxt_wrptr, nxt_rdptr;
  reg [asz:0] 		wrptr_p1, rdptr_p1;
  reg 			empty, full;

  reg [width-1:0] 	dout;
  reg 			irdy;
  reg 			nxt_irdy;
  assign 		trdy_in = !full;
  assign 		data_out = dout;
  assign 		irdy_out = irdy;
  
  always @*
    begin
      wrptr_p1 = wrptr + 1;
      rdptr_p1 = rdptr + 1;
      
      if (npt)
	begin
	  if (wrptr_p1[asz-1:0] == depth)
	    begin
	      wrptr_p1[asz-1:0] = 0;
	      wrptr_p1[asz] = ~wrptr[asz];
	    end
	  if (rdptr_p1[asz-1:0] == depth)
	    begin
	      rdptr_p1[asz-1:0] = 0;
	      rdptr_p1[asz] = ~rdptr[asz];
	    end
	end // if (npt)
      
      empty = (wrptr == rdptr);
      full = ((wrptr[asz-1:0] == rdptr[asz-1:0]) && 
	      (wrptr[asz] == ~rdptr[asz]));
	  
      if (irdy_in & !full)
	nxt_wrptr = wrptr_p1;
      else
	nxt_wrptr = wrptr;

      if (trdy_out & irdy)
	nxt_rdptr = rdptr_p1;
      else
	nxt_rdptr = rdptr;
	  
      nxt_irdy = (wrptr != nxt_rdptr);
    end
      
  always @(posedge clk)
    begin
      if (reset)
	begin
	  wrptr <= #1 0;
	  rdptr <= #1 0;
	  dout  <= #1 0;
	  irdy  <= #1 0;
	end
      else
	begin
	  wrptr <= #1 nxt_wrptr;
	  rdptr <= #1 nxt_rdptr;
	  irdy <= #1 nxt_irdy;
	  if (irdy_in & !full)
	    mem[wrptr[asz-1:0]] <= #1 data_in;
	  dout <= #1 mem[nxt_rdptr[asz-1:0]];
	end // else: !if(reset)
    end // always @ (posedge clk)

`ifdef DEPTH_MONITOR
  integer max_usage;
  integer usage;
  wire [asz-1:0] usage_gr;

  assign 	usage_gr = usage;
  
  initial 
    begin
      $display ("%m: Reporting in");
      max_usage = 0;
    end
  
  always @(posedge clk)
    begin : reporter
      if (!empty)
	begin
	  if (full)
	    usage = depth;
	  else if (wrptr[asz-1:0] < rdptr[asz-1:0])
	    usage = wrptr[asz-1:0] + depth - rdptr[asz-1:0];
	  else
	    usage = wrptr[asz-1:0] - rdptr[asz-1:0];

	  if (usage > max_usage)
	    max_usage = usage;
	end
    end

  always @(bench.report_depth)
    begin
      $display ("%m: max_usage=%0d depth=%0d", max_usage, depth);
    end
  
`endif
  
endmodule // it_fifo
