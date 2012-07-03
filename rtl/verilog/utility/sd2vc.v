//----------------------------------------------------------------------
// Srdy/Drdy to Valid/Credit interface conversion
//
// Halts timing on all output signals
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

module sd2vc
  #(parameter width=8,
    parameter cc_sz=2,
    parameter reginp=0)
  (
   input     clk,
   input     reset,

   input             c_srdy,
   output            c_drdy,
   input [width-1:0] c_data,


   output reg             p_vld,
   input                  p_cr,
   output reg [width-1:0] p_data
   );

  reg [cc_sz-1:0]         cc, nxt_cc;
  reg                     nxt_p_vld;
  wire                    in_cr;
  
  assign c_drdy = (cc != 0);

  always @*
    begin
      nxt_p_vld = (cc != 0) & c_srdy;

      if (nxt_p_vld & !p_cr)
        nxt_cc = cc - 1;
      else if (p_cr & ~nxt_p_vld & (cc != {cc_sz{1'b1}}))
        nxt_cc = cc + 1;
      else
        nxt_cc = cc;
    end

  always @(`SDLIB_CLOCKING)
    begin
      if (reset)
        begin
          /*AUTORESET*/
          // Beginning of autoreset for uninitialized flops
          cc <= {cc_sz{1'b0}};
          p_vld <= 1'h0;
          // End of automatics
        end
      else
        begin
          cc <= nxt_cc;
          p_vld <= nxt_p_vld;
        end
    end // always @ (posedge clk)

  always @(posedge clk)
    if (nxt_p_vld)
      p_data <= c_data;

  generate if (reginp == 1)
    begin : reginp_yes
      reg r_cr;
      always @(posedge clk)
        begin
          if (reset)
            r_cr <= 0;
          else
            r_cr <= p_cr;
        end
      assign in_cr = r_cr;
    end // block: reginp_yes
  else
    begin : reginp_no
      assign in_cr = p_cr;
    end
  endgenerate
  
  

endmodule // sd2vc
