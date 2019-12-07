//----------------------------------------------------------------------
// Two-cycle synchronizer
//
// This double-flop synchronizer is used inside of sd_fifo_s for 
// synchronization across clock domains when the "async" parameter is set.
//
// This sync flop has a simulation mode which implements recommendations
// from the Cummings 2008 SNUG paper regarding simulations with variable
// delays to simulate metastability events.  The DLY variable can be
// set during simulation to change the domain crossing time from two
// cycle to three cycle at any time.
//
// The inferred flops in this module are prefixed with "hgff" which
// allows them to be replaced with high-gain flip flops during the
// synthesis stage.  Alternately this module can be replaced with a
// technology-specific module which directly instantiates process-specific
// metastability-hardened flops.
//
// When run with AUTO_RANDOM_SYNC_DELAY, each synchronizer randomly 
// choses a delay value every three cycles, so a variety of sync
// delays will be used across the simulation.
//----------------------------------------------------------------------
// Author: Guy Hutchison
//
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

module sd_sync2
 #(parameter width=1)
 (
  input clk,
  input [width-1:0] sync_in,
  output [width-1:0] sync_out
 );

`ifdef SYNTHESIS
  logic [width-1:0] hgff_r1, hgff_r2;

  always @(posedge clk)
    begin
      hgff_r1 <= sync_in;
      hgff_r2 <= hgff_r1;
    end
  assign sync_out = hgff_r2;
`else
  logic [width-1:0] y1, r0, r1, r2;
  logic [width-1:0] DLY = {width{1'b0}};

  assign y1 = (~DLY & r0) | (DLY & r1);
  always @(posedge clk)
    begin
      r0 <= sync_in;
      r1 <= r0;
      r2 <= y1;
    end
  `ifdef AUTO_RANDOM_SYNC_DELAY
    always
      begin
        repeat (3)
          @(posedge clk);
        DLY = $random;
      end
  `endif
  assign sync_out = r2;
`endif

endmodule

