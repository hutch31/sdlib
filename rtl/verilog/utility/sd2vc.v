//----------------------------------------------------------------------
// Srdy/Drdy to Valid/Credit interface conversion
//
// Halts timing on all p-side output signals
// Halts timing on all p-side input signals when reginp == 1
//
// This block uses a post-reset handshake protocol with its pair
// module (vc2sd). The handshake pattern is
// the wakeup_pattern parameter, followed by its inverse.  This handshake
// pattern is issued every wakeup_interval cycles.  Once the module
// sees a credit issued from the pair side it assumes the handshake
// was received.
//
// For the handshake to work correctly the wakeup_interval must be
// larger than the round-trip delay; i.e. if the pair block is out
// of reset, then this module should see p_cr asserted before sending
// another handshake pattern.
//
// Naming convention: c = consumer, p = producer, i = internal interface
//----------------------------------------------------------------------
// Author: Guy Hutchison
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

module sd2vc
  #(parameter width=8,
    parameter cc_sz=2,
    parameter reginp=0,
    parameter wakeup_interval=32,
    parameter wakeup_pattern=2'b01)
  (
   input 		  clk,
   input 		  reset,

   input 		  c_srdy,
   output reg 		  c_drdy,
   input [width-1:0] 	  c_data,


   output reg 		  p_vld,
   input 		  p_cr,
   output reg [width-1:0] p_data
   );

  reg [cc_sz-1:0]         cc, nxt_cc;
  reg                     nxt_p_vld;
  wire                    in_cr;
  reg [1:0] 		  state, nxt_state;
  reg [width-1:0] 	  nxt_p_data;
  reg [$clog2(wakeup_interval)-1:0] wakeup_cnt, nxt_wakeup_cnt;
  
  localparam s_init = 0, s_run = 1, s_wake0 = 2, s_wake1 = 3;
  
  //assign c_drdy = (cc != 0);

  always @*
    begin
      nxt_state = state;
      nxt_p_data = c_data;
      nxt_wakeup_cnt = wakeup_cnt;
      //nxt_p_vld = (cc != 0) & c_srdy;
      nxt_cc = cc;

      case (state)
	s_init :
	  begin
	    c_drdy = 0;
	    nxt_p_vld = 0;
	    if (p_cr)
	      begin
		nxt_state = s_run;
		nxt_cc = 1;
	      end
	    else if (wakeup_cnt == (wakeup_interval-1))
	      nxt_state = s_wake0;
	    nxt_wakeup_cnt = wakeup_cnt + 1;
	  end

	s_run :
	  begin
	    nxt_p_vld = (cc != 0) & c_srdy;
	    c_drdy = (cc != 0);
	    
	    if (nxt_p_vld & !p_cr)
              nxt_cc = cc - 1;
	    else if (p_cr & ~nxt_p_vld & (cc != {cc_sz{1'b1}}))
              nxt_cc = cc + 1;
	  end
	
	s_wake0 :
	  begin
	    nxt_p_vld = 1;
	    nxt_p_data = wakeup_pattern;
	    nxt_state = s_wake1;
	  end

	s_wake1 :
	  begin
	    nxt_p_vld = 1;
	    nxt_p_data = ~wakeup_pattern;
	    nxt_wakeup_cnt = 0;
	    nxt_state = s_init;
	  end
      endcase
    end

  always @(`SDLIB_CLOCKING)
    begin
      if (reset)
        begin
          /*AUTORESET*/
	  // Beginning of autoreset for uninitialized flops
	  cc <= {cc_sz{1'b0}};
	  p_vld <= 1'h0;
	  state <= 2'h0;
	  wakeup_cnt <= {(1+($clog2(wakeup_interval)-1)){1'b0}};
	  // End of automatics
        end
      else
        begin
          cc <= nxt_cc;
          p_vld <= nxt_p_vld;
	  state <= nxt_state;
	  wakeup_cnt <= nxt_wakeup_cnt;
        end
    end // always @ (posedge clk)

  always @(posedge clk)
    if (nxt_p_vld)
      p_data <= nxt_p_data;

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
