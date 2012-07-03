//----------------------------------------------------------------------
// Valid/Credit FIFO Head "S"
//
// Alternate FIFO head block which interfaces to valid/credit interface.
// Only valid for power of 2 size due to usage calculation in head.
//
// Naming convention: c = consumer, p = producer, i = internal interface
//----------------------------------------------------------------------
// Author: Guy Hutchison
//
// This block is uncopyrighted and released into the public domain.
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

module vc_fifo_head_s
  #(parameter depth=16,
    parameter async=0,
    parameter asz=$clog2(depth)
    )
    (
     input       clk,
     input       reset,
     input       c_vld,
     output reg  c_cr,

     output [asz:0]     wrptr_head,
     output [asz-1:0]   wr_addr,
     output reg         wr_en,
     input [asz:0]      rdptr_tail,

     output [asz:0]     usage

     );

  reg [asz:0]           wrptr, nxt_wrptr;
  reg [asz:0]           wrptr_p1;
  reg                   full;
  wire [asz:0]          rdptr;
  wire [asz:0]          usage;
  reg [asz:0]           cissued, nxt_cissued;

  assign wr_addr = wrptr[asz-1:0];

  assign usage = (rdptr[asz] & !wrptr[asz]) ? depth + wrptr[asz-1:0] - rdptr[asz-1:0]  : wrptr - rdptr;
  
  always @*
    begin
      wrptr_p1 = wrptr + 1;
      
      full = ((wrptr[asz-1:0] == rdptr[asz-1:0]) && 
              (wrptr[asz] == ~rdptr[asz]));
          
      if (c_vld)
        nxt_wrptr = wrptr_p1;
      else
        nxt_wrptr = wrptr;

      wr_en = c_vld & !full;

      if (c_cr & !c_vld)
        nxt_cissued = cissued + 1;
      else if (c_vld & !c_cr)
        nxt_cissued = cissued - 1;
      else
        nxt_cissued = cissued;
    end
      
  always @(`SDLIB_CLOCKING)
    begin
      if (reset)
        begin
          wrptr <= `SDLIB_DELAY 0;
          cissued <= `SDLIB_DELAY 0;
          c_cr  <= 1'b0;
        end
      else
        begin
          wrptr <= `SDLIB_DELAY nxt_wrptr;
          cissued    <= `SDLIB_DELAY nxt_cissued;
          c_cr  <= ((cissued + usage) < (depth-1));
        end // else: !if(reset)
    end // always @ (posedge clk)

  function [asz:0] bin2grey;
    input [asz:0] bin_in;
    integer       b;
    begin
      bin2grey[asz] = bin_in[asz];
      for (b=0; b<asz; b=b+1)
        bin2grey[b] = bin_in[b] ^ bin_in[b+1];
    end
  endfunction // for

  function [asz:0] grey2bin;
    input [asz:0] grey_in;
    integer       b;
    begin
      grey2bin[asz] = grey_in[asz];
      for (b=asz-1; b>=0; b=b-1)
        grey2bin[b] = grey_in[b] ^ grey2bin[b+1];
    end
  endfunction

  assign wrptr_head = (async) ? bin2grey(wrptr) : wrptr;
  assign rdptr = (async)? grey2bin(rdptr_tail) : rdptr_tail;
  
endmodule