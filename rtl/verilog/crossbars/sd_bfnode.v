//----------------------------------------------------------------------
// Butterfly Switch Node
//
// Fundamental building block of Butterfly and Benes networks.
// Used in conjunction with butterfly network generator script
//----------------------------------------------------------------------
// Author: Guy Hutchison
//
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
 `define SDLIB_CLOCKING posedge clk
`endif

// delay unit for nonblocking assigns, default is to #1
`ifndef SDLIB_DELAY
 `define SDLIB_DELAY #1
`endif

module sd_bfnode
  #(parameter width=32,
    parameter abits=3,
    parameter asel=0)
  (input clk,
   input reset,

   input c_srdy_a,
   output c_drdy_a,
   input [abits-1:0] c_addr_a,
   input [width-1:0] c_data_a,

   input c_srdy_b,
   output c_drdy_b,
   input [abits-1:0] c_addr_b,
   input [width-1:0] c_data_b,

   output p_srdy_a,
   input p_drdy_a,
   output [abits-1:0] p_addr_a,
   output [width-1:0] p_data_a,

   output p_srdy_b,
   input p_drdy_b,
   output [abits-1:0] p_addr_b,
   output [width-1:0] p_data_b);

   wire [1:0] i_srdy;
   reg [1:0] i_drdy;
   wire [1:0][abits-1:0] i_addr;
   wire [1:0][width-1:0] i_data;
   //wire [width-1:0] i_data1;
   reg [1:0] o_srdy;
   wire [1:0] o_drdy;
   reg [1:0][width-1:0] o_data;
   reg [1:0][abits-1:0] o_addr;

   reg prio_b;  // indicates B interface has priority
   logic [1:0] dest;
   logic conflict;
   logic nxt_prio_b;

  wire [width+abits-1:0] temp_a, temp_b;
  wire [width+abits-1:0] tmp_inp_a, tmp_inp_b;

  sd_input #(.width(width+abits)) inp_a
   (.clk(clk),
    .reset(reset),
    .c_srdy (c_srdy_a),
    .c_drdy (c_drdy_a),
    .c_data ({c_addr_a,c_data_a}),

    .ip_srdy (i_srdy[0]),
    .ip_drdy (i_drdy[0]),
    .ip_data (tmp_inp_a));
  assign {i_addr[0], i_data[0]} = tmp_inp_a;

  sd_input #(.width(width+abits)) inp_b
    (.clk(clk),
     .reset(reset),
     .c_srdy (c_srdy_b),
     .c_drdy (c_drdy_b),
     .c_data ({c_addr_b,c_data_b}),

     .ip_srdy (i_srdy[1]),
     .ip_drdy (i_drdy[1]),
     .ip_data (tmp_inp_b));
  assign {i_addr[1], i_data[1]} = tmp_inp_b;

  sd_output #(.width(width+abits)) outp_a
    (.clk (clk),
     .reset (reset),
     .ic_srdy (o_srdy[0]),
     .ic_drdy (o_drdy[0]),
     .ic_data ({o_addr[0], o_data[0]}),

     .p_srdy (p_srdy_a),
     .p_drdy (p_drdy_a),
     .p_data (temp_a));
  assign {p_addr_a, p_data_a} = temp_a;

  sd_output #(.width(width+abits)) outp_b
   (.clk (clk),
    .reset (reset),
    .ic_srdy (o_srdy[1]),
    .ic_drdy (o_drdy[1]),
    .ic_data ({o_addr[1], o_data[1]}),

    .p_srdy (p_srdy_b),
    .p_drdy (p_drdy_b),
    .p_data (temp_b));
  assign {p_addr_b, p_data_b} = temp_b;

  always @*
    begin
      dest[0] = i_addr[0][asel];
      dest[1] = i_addr[1][asel];
      conflict = (i_srdy == 2'b11) & (i_addr[0][asel] == i_addr[1][asel]);
      nxt_prio_b = prio_b;

      if ((i_srdy[0] & !i_srdy[1]) | (conflict & !prio_b))
        begin
          o_srdy = { i_srdy[0] ^ ~dest[0], i_srdy[0] ^ dest[0]};
          //i_drdy[0] = (o_drdy[0] ^ ~dest[0]) | (o_drdy[0] ^ dest[0]);
          i_drdy[0] = o_drdy[dest[0]];
          i_drdy[1] = 1'b0;
          o_data[dest[0]] = i_data[0];
          o_addr[dest[0]] = i_addr[0];
          o_data[~dest[0]] = {width{1'b0}};
          o_addr[~dest[0]] = {abits{1'b0}};
          if (conflict) nxt_prio_b = ~prio_b;
        end
      else if ((!i_srdy[0] & i_srdy[1]) | (conflict & prio_b))
        begin
          o_srdy = { i_srdy[1] ^ ~dest[1], i_srdy[1] ^ dest[1]};
          //i_drdy[1] = (o_drdy[0] ^ ~dest[1]) | (o_drdy[0] ^ dest[1]);
          i_drdy[1] = o_drdy[dest[1]];
          i_drdy[0] = 1'b0;
          o_data[dest[1]] = i_data[1];
          o_addr[dest[1]] = i_addr[1];
          o_data[~dest[1]] = {width{1'b0}};
          o_addr[~dest[1]] = {abits{1'b0}};
          if (conflict) nxt_prio_b = ~prio_b;
        end
      else if (i_srdy == 2'b11)
        begin
          o_srdy = 2'b11;
          if (i_addr[0][asel] == 1'b0)
            begin // straight
              i_drdy = o_drdy;
              o_data = i_data;
              o_addr = i_addr;
            end
          else // swapped
            begin
              i_drdy = { o_drdy[0], o_drdy[1] };
              o_data[0] = i_data[1];
              o_data[1] = i_data[0];
              o_addr[0] = i_addr[1];
              o_addr[1] = i_addr[0];
            end
        end
      else
        begin
          o_srdy = 2'b0;
          i_drdy = 2'b0;
          o_addr = {abits*2{1'b0}};
          o_data = {width*2{1'b0}};
        end
    end

  always @(`SDLIB_CLOCKING)
    begin
      if (reset)
        begin
          prio_b <= 1'b0;
        end
      else
        begin
          prio_b <= `SDLIB_DELAY nxt_prio_b;
        end
    end

endmodule
