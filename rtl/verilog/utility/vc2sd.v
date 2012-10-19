//----------------------------------------------------------------------
// Valid/Credit to Srdy-Drdy Converter
//
// Converts a valid-credit interface to an srdy-drdy interface using
// a small built-in FIFO.
//
// Halts timing on all c-side output signals.
// Halts timing on all c-side input signals when reginp == 1
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

module vc2sd
  #(parameter depth=16,
    parameter asz=$clog2(depth),
    parameter width=8,
    parameter reginp=0
    )
    (
     input       clk,
     input       reset,
     input       c_vld,
     output reg  c_cr,
     input [width-1:0] c_data,

     output reg             p_srdy,
     input                  p_drdy,
     output [width-1:0]     p_data
     );

  localparam npt = (depth != (2**asz));

  reg [asz:0]           wrptr, nxt_wrptr;
  reg [asz:0]           wrptr_p1;
  reg                   full;
  reg [asz:0]           rdptr;
  //wire [asz:0]          usage;
  reg [asz:0]           usage, nxt_usage;
  wire [asz:0]          crtotal;
  reg [asz:0]           cissued, nxt_cissued;
  wire                  in_vld;
  reg [asz:0]           nxt_rdptr;
  reg [asz:0]           rdptr_p1;
  reg                   empty;
  reg                   nxt_p_srdy;
  //reg                   rd_en;
  reg                   wr_en;
  wire [width-1:0]      wr_data;
  wire [asz-1:0]        rd_addr;
  reg                   nxt_c_cr;

  reg [width-1:0]       buffer [0:depth-1];

  //assign o_usage = (rdptr[asz] & !wrptr[asz]) ? depth + wrptr[asz-1:0] - rdptr[asz-1:0]  : wrptr - rdptr;

  assign crtotal = usage + cissued + c_cr;
  
  always @*
    begin
      if (npt && (wrptr == (depth-1)))
        wrptr_p1 = 0;
      else
        wrptr_p1 = wrptr + 1;

      if (npt)
        full = (usage == depth);
      else
        full = ((wrptr[asz-1:0] == rdptr[asz-1:0]) && 
                (wrptr[asz] == ~rdptr[asz]));
          
      if (in_vld)
        nxt_wrptr = wrptr_p1;
      else
        nxt_wrptr = wrptr;

      wr_en = in_vld & !full;

      if (c_cr & !in_vld)
        nxt_cissued = cissued + 1;
      else if (in_vld & !c_cr)
        nxt_cissued = cissued - 1;
      else
        nxt_cissued = cissued;

      nxt_c_cr = (crtotal < depth);

      if (in_vld & ~(p_srdy & p_drdy))
        nxt_usage = usage + 1;
      else if ((p_srdy & p_drdy) & ~in_vld)
        nxt_usage = usage - 1;
      else
        nxt_usage = usage;
    end
      
  always @(`SDLIB_CLOCKING)
    begin
      if (reset)
        begin
          wrptr   <= `SDLIB_DELAY 0;
          cissued <= `SDLIB_DELAY 0;
          c_cr    <= `SDLIB_DELAY 1'b0;
          usage   <= `SDLIB_DELAY 0;
        end
      else
        begin
          wrptr   <= `SDLIB_DELAY nxt_wrptr;
          cissued <= `SDLIB_DELAY nxt_cissued;
          c_cr    <= `SDLIB_DELAY (crtotal < depth);
          usage   <= `SDLIB_DELAY nxt_usage;
        end // else: !if(reset)
    end // always @ (posedge clk)

  generate if (reginp == 1)
    begin : reginp_yes
      reg r_vld;
      reg [width-1:0] r_data;
      always @(posedge clk)
        begin
          if (reset)
            r_vld <= 0;
          else
            r_vld <= c_vld;
        end
      always @(posedge clk)
        begin
          r_data <= c_data;
        end
      
      assign in_vld = r_vld;
      assign wr_data = r_data;
    end // block: reginp_yes
  else
    begin : reginp_no
      assign in_vld = c_vld;
      assign wr_data = c_data;
    end
  endgenerate

  always @*
    begin
      if (npt && (rdptr == (depth-1)))
        rdptr_p1 = 0;
      else
        rdptr_p1 = rdptr + 1;
      
      empty = (wrptr == rdptr);

      if (p_drdy & p_srdy)
        nxt_rdptr = rdptr_p1;
      else
        nxt_rdptr = rdptr;
          
      nxt_p_srdy = (wrptr != nxt_rdptr);
      //rd_en = (p_drdy & p_srdy) | (!empty & !p_srdy);
    end
      
  always @(`SDLIB_CLOCKING)
    begin
      if (reset)
        begin
          rdptr <= `SDLIB_DELAY 0;
          p_srdy  <= `SDLIB_DELAY 0;
        end
      else
        begin
          rdptr <= `SDLIB_DELAY nxt_rdptr;
          p_srdy <= `SDLIB_DELAY nxt_p_srdy;
        end // else: !if(reset)
    end // always @ (posedge clk)

  always @(posedge clk)
    begin
      if (wr_en)
        buffer[wrptr[asz-1:0]] <= wr_data;      
    end

  assign rd_addr = rdptr[asz-1:0];
  assign p_data = buffer[rd_addr];

endmodule
  
