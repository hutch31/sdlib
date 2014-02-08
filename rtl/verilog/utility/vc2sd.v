//----------------------------------------------------------------------
// Valid/Credit to Srdy-Drdy Converter
//
// Converts a valid-credit interface to an srdy-drdy interface using
// an external FIFO.  This block is meant to be paired with an sd_fifo_c
// but can be used with any FIFO which updates its usage one cycle
// after p_srdy is asserted.
//
// p_drdy in this module is used only for error checking (overflow).
//
// This block uses a post-reset handshake protocol with its pair
// module (sd2vc) so that it does not issue credits until both
// modules have been released from reset.  The handshake pattern is
// the wakeup_pattern parameter, followed by its inverse.  Until
// the handshake pattern is seen all input is ignored.
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

module vc2sd
  #(parameter depth=16,
    parameter asz=$clog2(depth),
    parameter usz=$clog2(depth+1),
    parameter width=8,
    parameter reginp=0,
    parameter wakeup_pattern=1
    )
    (
     input 		clk,
     input 		reset,
     input 		c_vld,
     output reg 	c_cr,
     input [width-1:0] 	c_data,

     input [usz-1:0] 	p_usage,
     output reg 	p_srdy,
     input 		p_drdy,
     output [width-1:0] p_data
     );

  localparam cr_sz = $clog2(depth+2);
  reg [width-1:0] 	    r_data;
  reg 			    r_vld;
   reg [1:0] 		  state, nxt_state;
  reg [usz-1:0] 		  cissued, nxt_cissued;
  wire [cr_sz-1:0] 		  crtotal;
  reg 			  nxt_c_cr;
  wire 			  overflow;
  
  localparam s_init = 0, s_run = 1, s_wake0 = 2, s_wake1 = 3;
  assign crtotal = p_usage + cissued + c_cr;

  assign overflow = p_srdy & ~p_drdy;

  always @(posedge clk)
    begin
      r_data <= c_data;
      r_vld  <= c_vld;
    end
  assign p_data = r_data;
  
  always @*
    begin
      p_srdy = 0;
      nxt_c_cr = 0;
      nxt_state = state;
      nxt_cissued = cissued;
      
      case (state)
	s_init :
	  begin
	    if (r_vld && (r_data == wakeup_pattern))
	      nxt_state = s_wake0;
	  end

	s_wake0 :
	  begin
	    if (r_vld && (r_data == ~wakeup_pattern))
	      begin
		nxt_cissued = 0;
		nxt_state = s_run;
	      end
	    else
	      nxt_state = s_init;
	  end

	s_run :
	  begin
	    p_srdy = r_vld;
	    
	    if (c_cr & !r_vld)
              nxt_cissued = cissued + 1;
	    else if (r_vld & !c_cr)
              nxt_cissued = cissued - 1;
	    else
              nxt_cissued = cissued;
	    
	    nxt_c_cr = (crtotal < depth);
	  end // case: s_run

	default :
	  nxt_state = s_init;
      endcase
    end
  
  always @(`SDLIB_CLOCKING)
    begin
      if (reset)
        begin
          cissued <= `SDLIB_DELAY 0;
          c_cr    <= `SDLIB_DELAY 1'b0;
	  state   <= `SDLIB_DELAY s_init;
        end
      else
        begin
          cissued <= `SDLIB_DELAY nxt_cissued;
          c_cr    <= `SDLIB_DELAY nxt_c_cr;
	  state   <= `SDLIB_DELAY nxt_state;
        end // else: !if(reset)
    end // always @ (posedge clk)
  
endmodule // vc2sd
