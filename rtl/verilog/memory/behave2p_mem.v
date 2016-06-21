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

// delay unit for nonblocking assigns, default is to #1
`ifndef SDLIB_DELAY 
 `define SDLIB_DELAY #1 
`endif

module behave2p_mem
  #(parameter width=8,
    parameter depth=256,
    parameter addr_sz=$clog2(depth),
    parameter reg_rd_addr=1)
  (/*AUTOARG*/
  // Outputs
  d_out,
  // Inputs
  wr_en, rd_en, wr_clk, rd_clk, d_in, rd_addr, wr_addr
  );
  input        wr_en, rd_en, wr_clk;
  input        rd_clk;
  input [width-1:0] d_in;
  input [addr_sz-1:0] rd_addr, wr_addr;

  output [width-1:0]  d_out;

  logic [addr_sz-1:0] r_addr;

  reg [width-1:0]   array[0:depth-1];
  
  always @(posedge wr_clk)
    begin
      if (wr_en)
        begin
          array[wr_addr] <= `SDLIB_DELAY d_in;   // ri lint_check_waive VAR_INDEX_RANGE
        end
    end

  generate if (reg_rd_addr == 1)
    begin : gen_reg_rd
      always @(posedge rd_clk)
        begin
          if (rd_en)
            begin
              r_addr <= `SDLIB_DELAY rd_addr;
            end
        end // always @ (posedge clk)
    end
  else
    begin : gen_noreg_rd
      assign r_addr = rd_addr;
    end
  endgenerate

  assign d_out = array[r_addr]; // ri lint_check_waive VAR_INDEX_RANGE

`ifdef SD_INLINE_ASSERTION_ON
logic [addr_sz-1:0] rd_idx, wr_idx;
always @(posedge clk) begin
    if(reset) begin
	rd_idx <= {addr_sz{1'b0}};
	wr_idx <= {addr_sz{1'b0}};
    end else begin
	rd_idx <= r_addr;
	wr_idx <= wr_addr;
    end
end

ERROR_ADDR_OUT_RANGE: assert property
	(@(posedge clk) disable iff (reset) ((rd_idx<depth)&&(wr_idx<depth)) )
`endif

endmodule
