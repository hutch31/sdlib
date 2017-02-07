//----------------------------------------------------------------------
// Author: Frank Wang
// 
// Variant of sd_fifo_c, always write to last location and then shift
// This module is intended to be used at the primary input port in registered in/out design flow.
//
// All timing path are internall, there is no input-write/read-output signal fan-out issue.
// Input c_data are registered without fan-out, c_srdy goes through one combo gate before being registered.
// Output c_drdy goes through a narrow comparator before driving out.
//
//----------------------------------------------------------------------
`ifndef _SD_FIFO_TAILWR_V_
`define _SD_FIFO_TAILWR_V_
module sd_fifo_tailwr #(
    parameter width=8,
    parameter rst_sz=0, //upper bits of data to reset if reset is asserted
    parameter depth=16,
    parameter usz=$clog2(depth+1)
) (
    input   clk,
    input   reset,

    input   logic [width-1:0] c_data,
    input   logic             c_srdy,
    output  logic             c_drdy,

    output  logic [width-1:0] p_data,
    output  logic             p_srdy,
    input   logic             p_drdy,

    output  logic [usz-1:0]   nxt_usage,
    output  logic [usz-1:0]   usage
);

localparam asz=$clog2(depth);
logic [depth-1:0][width-1:0]  data_buf;
logic [depth-1:0][width-1:0]  nxt_data_buf;
logic rd_vld;
logic wr_vld;
logic wr_vld_d;
logic rd_vld_d;
logic [usz-1:0]   partial_usage;
logic [usz-1:0]   nxt_partial_usage;
logic [usz-1:0]   nxt_complete_usage;
logic buf_shift;
logic buf_wr_en;
logic [asz-1:0] buf_rd_ptr;
//logic [usz-1:0] usage_d;
logic nxt_buf_shift;
logic nxt_buf_wr_en;
logic [asz-1:0] nxt_buf_rd_ptr;

assign rd_vld = p_srdy && p_drdy;
assign wr_vld = c_srdy && c_drdy;
  
assign c_drdy = (usage < depth);
//always @(posedge clk) begin
//    if (reset)                          c_drdy <= 1'b0;
//    else if(usage < depth)              c_drdy <= 1'b1;
//    else if((usage == depth) && p_drdy) c_drdy <= 1'b1;
//    else                                c_drdy <= 1'b0;
//end
// read from fifo
assign p_srdy = (usage > 0);
assign p_data = data_buf[buf_rd_ptr];   // ri lint_check_waive VAR_INDEX_RANGE

// writing and shifting of FIFO
always @(*) begin
    nxt_data_buf = data_buf;
    if(nxt_buf_shift) begin  // shifting
        for(int i=0; i<depth-1; i=i+1) begin
            nxt_data_buf[i] = data_buf[i+1];
        end
    end
    if(nxt_buf_wr_en) begin
        nxt_data_buf[depth-1] = c_data;
    end
end
always @(posedge clk) begin
    data_buf <= nxt_data_buf;
//    if(rst_sz>0)
//        if(reset) data_buf[depth-1][width-1 -: rst_sz] <= {rst_sz{1'b0}};
end

// control
// number two of total two fan-out for c_srdy
assign nxt_complete_usage  = usage         + wr_vld   - rd_vld;
assign nxt_partial_usage   = partial_usage + wr_vld_d - rd_vld;
assign usage = wr_vld_d + partial_usage;
assign nxt_usage = nxt_complete_usage;
always @(posedge clk) begin
    if(reset) begin
        wr_vld_d <= 1'b0;
        partial_usage    <= {usz{1'b0}};
        buf_shift   <= 1'b0;
        buf_wr_en   <= 1'b0;
        buf_rd_ptr  <= depth[asz-1:0]-1'b1;
        //usage_d     <= {usz{1'b0}};
    end else begin
        wr_vld_d <= wr_vld;
        rd_vld_d <= p_srdy && p_drdy;
        partial_usage   <= nxt_partial_usage;
        buf_shift   <= nxt_buf_shift;
        buf_wr_en   <= nxt_buf_wr_en;
        buf_rd_ptr  <= nxt_buf_rd_ptr;
        //usage_d     <= usage;
    end
end
always @(*) begin
    nxt_buf_shift = ((usage < depth) && wr_vld_d) || ((usage == depth-1) && rd_vld_d);  // ri lint_check_waive COMP_OP_BITLEN
    nxt_buf_wr_en = (usage < depth) ; //|| (p_srdy && p_drdy);
    nxt_buf_rd_ptr = ( nxt_buf_shift &&  (p_srdy && p_drdy)) ? buf_rd_ptr      :
                     ( nxt_buf_shift && ~(p_srdy && p_drdy)) ? buf_rd_ptr-1'b1 :
                     (~nxt_buf_shift &&  (p_srdy && p_drdy)) ? buf_rd_ptr+1'b1 : buf_rd_ptr;
end

`ifdef SD_INLINE_ASSERTION_ON
logic [usz-1:0]   complete_usage;
always @(posedge clk) begin
    if(reset) begin
        complete_usage   <= {usz{1'b0}};
    end else begin
        complete_usage   <= nxt_complete_usage;
    end
end

logic fifo_full;
logic chk_usage;

assign fifo_full = (usage >= depth);
assign chk_usage = (complete_usage == usage);

COVER_FIFO_FULL: cover property 
        (@(posedge clk) disable iff (reset) fifo_full);
ERROR_FIFO_USAGE: assert property 
        (@(posedge clk) disable iff (reset) (complete_usage == usage));

logic [asz-1:0] rd_ptr_idx;
always @(posedge clk) begin
    if(reset) begin
	rd_ptr_idx <= {asz{1'b0}};
    end else begin        
	rd_ptr_idx <= nxt_buf_rd_ptr;
    end
end

ERROR_PTR_OUT_RANGE:assert property
	(@(posedge clk) disable iff (reset) (rd_ptr_idx < depth));
`endif 
  
endmodule // sd_fifo_tailwr
// Local Variables:
// End:
`endif //  _SD_FIFO_TAILWR_V_

