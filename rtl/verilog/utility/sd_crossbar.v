//----------------------------------------------------------------------
// Srdy/Drdy input block
//
// Halts timing on c_drdy.  Intended to be used on the input side of
// a design block.
//
// Naming convention: c = consumer, p = producer, i = internal interface
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
 `define SDLIB_CLOCKING posedge clk or posedge reset
`endif

// delay unit for nonblocking assigns, default is to #1
`ifndef SDLIB_DELAY 
 `define SDLIB_DELAY #1 
`endif

module sd_crossbar
  #(parameter inputs=4,
    parameter outputs=4,
    parameter asz=$clog2(outputs),
    parameter width=8,
    parameter ipipe=0)
  (
   input                                 clk,
   input                                 reset,
   
   input [inputs-1:0]                    in_srdy,
   output logic [inputs-1:0]             in_drdy,
   input [inputs-1:0][asz-1:0]           in_addr,
   input [inputs-1:0][width-1:0]         in_data,
   output logic [outputs-1:0]            out_srdy,
   input logic [outputs-1:0]             out_drdy,
   output logic [outputs-1:0][width-1:0] out_data,

   output                                int_oflow
   );

  genvar                           x, y;
  integer                          i;
  logic [outputs-1:0][width-1:0]   xbarout;
  logic [outputs-1:0]              xbarvld;
  logic [outputs-1:0][width-1:0]   r_xbarout;
  logic [outputs-1:0]              r_xbarvld;
  logic [outputs-1:0]              a_vld, b_vld;
  logic [outputs-1:0][width-1:0]   a_buf, b_buf;
  //logic [inputs-1:0][outputs-1:0]  select;
  logic [outputs-1:0][inputs-1:0]  selected;

  logic [inputs-1:0]               rin_srdy;
  logic [inputs-1:0]               rin_drdy;
  logic [inputs-1:0][asz-1:0]      rin_addr;
  logic [inputs-1:0][width-1:0]    rin_data;
  logic [outputs-1:0]              out_accept;
  logic [outputs-1:0]              oflow_check;

  assign int_oflow = |oflow_check;
                                        
  function [inputs-1:0] nxt_grant;
    input [inputs-1:0] cur_grant;
    input [inputs-1:0] cur_req;
    reg [inputs-1:0]   msk_req;
    reg [inputs-1:0]   tmp_grant;
    begin
      msk_req = cur_req & ~((cur_grant - 1) | cur_grant);
      tmp_grant = msk_req & (~msk_req + 1);

      if (msk_req != 0)
        nxt_grant = tmp_grant;
      else
        nxt_grant = cur_req & (~cur_req + 1);
    end
  endfunction // if

  generate
    for (y=0; y<inputs; y++)
      begin : in_hold
        sd_iofull #(.width(width+asz), .isinput(1)) reg_input
           (.clk (clk),
            .reset (reset),
            .c_srdy (in_srdy[y]),
            .c_drdy (in_drdy[y]),
            .c_data ({in_addr[y],in_data[y]}),
            .p_srdy (rin_srdy[y]),
            .p_drdy (rin_drdy[y]),
            .p_data ({rin_addr[y],rin_data[y]}));
      end // block: in_hold
  endgenerate
  
  generate
    for (y=0; y<outputs; y++)
      begin : out_bus
        logic [inputs-1:0] requests;
        logic [outputs-1:0] grant;
        logic [outputs-1:0] grantarb;
        logic               valid_req;
        
        always @(posedge clk)
          begin
            if (reset)
              grant <= {inputs{1'b0}};
            else
              grant <= grantarb;
          end

        always @*
          begin
            requests = 0;

            for (i=0; i<inputs;i=i+1)
              requests[i] = rin_srdy[i] & (rin_addr[i] == y);

            grantarb = nxt_grant(grant[y], requests);
            valid_req = |(rin_srdy & grantarb);
            selected[y] = grantarb;
          end
              
        always @*
          begin
            xbarout[y] = {width{1'b0}};

            for (i=0; i<inputs; i=i+1)
              begin
                xbarout[y] = xbarout[y] | ({width{grantarb[i]}} & rin_data[i]);
              end
            xbarvld[y] = valid_req && out_accept[y];
          end // always @ *

        
        // Provide two slots of output buffering on the crossbar
        // Only schedule a transaction for this output if at least
        // one slot is free
        logic [$clog2(3+ipipe)-1:0] usage;
        logic       oflow_drdy;
        assign out_accept[y] = (usage < 2);
        assign oflow_check[y] = ~oflow_drdy & r_xbarvld[y];
        
        sd_fifo_c #(.width(width), .depth(2+ipipe)) twoslot
          (
           .usage                       (usage),
           .clk                         (clk),
           .reset                       (reset),
           
           .c_drdy                      (oflow_drdy),
           .c_srdy                      (r_xbarvld[y]),
           .c_data                      (r_xbarout[y]),
           
           .p_srdy                      (out_srdy[y]),
           .p_data                      (out_data[y]),
           .p_drdy                      (out_drdy[y]));
      end
         
  endgenerate

  generate
    if (ipipe > 1)
      begin : multi_pipeline
        logic [ipipe-1:0][outputs-1:0][width-1:0] xbdata;
        logic [ipipe-1:0][outputs-1:0]            xbvld;
        integer                                   p;

        always @(posedge clk)
          begin
            for (p=0; p<(ipipe-1); p=p+1)
              begin
                xbdata[p] <= xbdata[p+1];
                xbvld[p]  <= xbvld[p+1];
              end
            xbdata[ipipe-1] <= xbarout;
            xbvld[ipipe-1]  <= xbarvld;
          end

        assign r_xbarout = xbdata[0];
        assign r_xbarvld = xbvld[0];
      end
    else if (ipipe == 1)
      begin : internal_pipeline
        always @(posedge clk)
          begin
            r_xbarout <= xbarout;
            r_xbarvld <= xbarvld;
          end
      end
    else
      begin : no_pipeline
        assign r_xbarout = xbarout;
        assign r_xbarvld = xbarvld;
      end
  endgenerate
  
  integer d, dd;
  
  always @*
    begin
      rin_drdy = 0;

      for (d=0; d<inputs; d=d+1)
        begin
          rin_drdy[d] = 0;
          for (dd=0; dd<outputs; dd=dd+1)
            if (selected[dd][d] & out_accept[dd])
              rin_drdy[d] = 1;
        end
    end // always @ *

endmodule // fullcrossbar
