//----------------------------------------------------------------------
// Author: Frank Wang
//
// Srdy/Drdy Delayed Flow Control Receiver with flow control override
//
// Converter block between srdy/drdy protocol and delayed
// flow control (system where srdy and drdy are registered).
// The delay parameter should be set to the combined
// round-trip delay of the system.
//
// This block is optimized for P&R block primary input interface in registered input/output design flow.
//
// Parameters:
//   width : datapath width
//   rt_lat : round-trip latency of vld/data and fc_n
//   thd : threshold value to begin de-asserting fc_n
//         minimally, need to be the latency from c_vld to fifo output s/drdy to rx_ctl f_usage!
//   regcout : flop c_fc_n output, 
//             when not set, c_fc_n output pin is driven from a OR gate after a comparator
//             The default value minimizes c_fc_n output timing by setting value of 1
//   regcin :  flop c_vld/c_data input 
//             when set, input c_vld and c_data is flopped inside this control module. 
//             It should usually not be set when this module is used inside the sd_dfc_rx module.
//             see sd_dfc_rx modules for more details.
//   depth: external latency (rt_lat) + tx latency (1) 
//          + rx latency (regcout + regcin) + fifo latency (1 if fifo.usage is flopped)
//
//----------------------------------------------------------------------

`ifndef _SD_DFC_RX_CTL_V_
`define _SD_DFC_RX_CTL_V_

module sd_dfc_rx_ctl #(
    parameter width=8,
    parameter rt_lat=8,
    parameter thd=3,
    parameter regcout=1, //if set, register c_fc_n
    parameter regcin=1, //if set, register c_vld and c_data
    // +1 for tx latency, +1 if using registered usage from the FIFO.
    parameter depth=rt_lat + thd + regcout + regcin + 2,
    parameter usz = $clog2(depth+1)
) (
    input              clk,
    input              rst,
    input logic        force_stop,

    input              c_vld,
    output logic       c_fc_n,
    input [width-1:0]  c_data,

    input  logic       f_pop_vld,
    output             f_srdy,
    input              f_drdy,
    output [width-1:0] f_data,
    output logic       overflow,
    input  [usz-1:0]   f_usage

);

logic ic_fc_n;
logic ic_vld;
logic [width-1:0] ic_data;
/*AUTOLOGIC*/

// c_fc_n output
generate if(regcout) begin: reg_fc_n
    always @(posedge clk) begin
        if(rst) begin
            c_fc_n <= 1'b0;
        end else begin
            c_fc_n <= ic_fc_n;
        end
    end
end else begin : wire_fc_n
    assign c_fc_n = ic_fc_n;
end
endgenerate
// c_vld input
generate if(regcin) begin: reg_vld
    always @(posedge clk) begin
        if(rst) begin
            ic_vld <= 1'b0;
        end else begin
            ic_vld <= c_vld;
        end
        ic_data <= c_data;
    end
end else begin : wire_vld
    assign ic_vld = c_vld;
    assign ic_data = c_data;
end
endgenerate

// when f_drdy is high (i.e. fifo is not full), in three cases, c_fc_n should be high:
// 1. when fifo usgae is less than thd.
// 2. when fifo is draining, regardless of usage.
logic              f_wr_vld;
logic              force_stop_d;
assign f_wr_vld = f_srdy && f_drdy;
always @(posedge clk) begin
    if(rst) begin
        overflow <= 1'b0;
    end else begin
        overflow <= ic_vld && (~f_drdy);
    end
    force_stop_d <= force_stop;
end
assign ic_fc_n = (~force_stop_d) && /*(f_usage < depth) &&*/ ((f_usage < thd) || (f_pop_vld));
// FIFO interface
assign f_srdy = ic_vld;
assign f_data = ic_data;
//assign overflow = (f_usage > depth);


`ifdef SIMULATION
    `ifndef SD_INLINE_ASSERTION_OFF // these assertions are by default on in simulation
logic assert_on;
initial begin
    assert_on=1'b1;
end
ERROR_DFC_RX_CTL_OVERFLOW_a: assert property (@(posedge clk) 
        disable iff(rst || (~assert_on)) (ic_vld |-> f_drdy));
COVER_DFC_RX_CTL_FIFO_FULL_cp : cover property (@(posedge clk) 
        disable iff(rst || (~assert_on)) (f_usage == depth));
    `endif
`endif

endmodule

`endif //_SD_DFC_RX_CTL_V_
// Local Variables:
// verilog-library-directories:("." "../buffers")
// End:
