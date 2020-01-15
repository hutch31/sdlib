//----------------------------------------------------------------------
// Author: Frank Wang
//
// This module is functionally equivalent to sd_iofull_legacy
// But this verison does not use srdy/drdy signals for clock gating directly
//     intead, srdy/drdy fan-out to a few internal state signals, which then
//     dictate loading and poping of an internal 2-entry buffer.
// p_srdy and c_drdy comes directly from flop
// c_drdy and p_drdy are lightly loaded to the interal control flops
//
//----------------------------------------------------------------------
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

`ifndef _SD_IOFULL_V_
    `define _SD_IOFULL_V_
// Clocking statement for synchronous blocks.  Default is for
// posedge clocking and positive async reset
`ifdef SDLIB_ASYNC_RESET
 `define SDLIB_CLOCKING posedge clk or posedge reset
`else
 `define SDLIB_CLOCKING posedge clk
`endif

// delay unit for nonblocking assigns, default is to #1
`ifndef SDLIB_DELAY
 `define SDLIB_DELAY #1
`endif

module sd_iofull #(
    //parameter ctrl_rep=1, // number of groups to divide the main data bus to reduce fan-out
    parameter ctrl_fanout=64,
    parameter width = 8
) (
    input  logic              clk,
    input  logic              reset,
    input  logic              c_srdy,
    output logic              c_drdy,
    input  logic [width-1:0]  c_data,

    output logic              p_srdy,
    input  logic              p_drdy,
    output logic [width-1:0]  p_data
);

//    parameter ctrl_fanout=128, // number of data bits each mux sel bit controls
//                            // smaller ctrl_fanout marginally increase the c_srdy and p_drdy fan-out

//localparam int ctrl_rep = (int(width*1000/ctrl_fanout) == int((width/ctrl_fanout)*1000)) ?
//                                    int(width/ctrl_fanout) : int(width/ctrl_fanout+1);

localparam int tmp_modulos=width%ctrl_fanout;
localparam int ctrl_rep = (tmp_modulos==0) ? width/ctrl_fanout : (width/ctrl_fanout + 1);

localparam int lfo=width/ctrl_rep;
localparam int hfo=width-lfo*(ctrl_rep-1);

// S_0_0: both hold flop empty
// S_1_2: hold flop 0 is tail, holding flop 1 is head
typedef enum logic [1:0] {S_0_0,S_1_0,S_0_1, S_2_1} STATE_E_S;
STATE_E_S state;
STATE_E_S nxt_state;
logic [width-1:0]   hold_1;
logic [width-1:0]   hold_0;
logic        nxt_shift;
logic        nxt_load;
logic        nxt_send_sel;
logic [ctrl_rep-1:0]  shift;
logic [ctrl_rep-1:0]  load;
logic [ctrl_rep-1:0]  send_sel;

// State control
logic push_vld;
logic pop_vld;
assign push_vld = c_srdy && c_drdy;
assign pop_vld  = p_srdy && p_drdy;
always @(*) begin
    nxt_state = state;
    case (state)
    S_0_0:  begin
        if(push_vld)                        nxt_state = S_1_0;
    end
    S_1_0:  begin
        if     (push_vld && p_drdy)         nxt_state = S_1_0;
        else if((push_vld) && (~p_drdy))    nxt_state = S_2_1;
        else if((~push_vld) && (p_drdy))    nxt_state = S_0_0;
        else if((~push_vld) && (~p_drdy))   nxt_state = S_0_1;
    end
    S_0_1:  begin
        if     (push_vld && p_drdy)         nxt_state = S_1_0;
        else if((push_vld) && (~p_drdy))    nxt_state = S_2_1;
        else if((~push_vld) && (p_drdy))    nxt_state = S_0_0;
        else if((~push_vld) && (~p_drdy))   nxt_state = S_0_1;
    end
    S_2_1:  begin
        if((~push_vld) && (p_drdy))         nxt_state = S_1_0;
    end
    default: begin
        nxt_state = state;  //ri lint_check_waive UNREACHABLE
    end
    endcase
end
always @(`SDLIB_CLOCKING) begin
//always @(posedge clk) begin
    if(reset)
        state  <= S_0_0;
    else
        state  <= nxt_state;
end

// holding data control
always @(*) begin
    nxt_shift = 1'b0;
    nxt_load = 1'b0;
    case (nxt_state)
    S_0_0:  begin
        nxt_shift = 1'b0;
        nxt_load  = 1'b1;
    end
    S_0_1:  begin
        nxt_load = 1'b1;
    end
    S_1_0:  begin
        nxt_shift = 1'b1;
        nxt_load  = 1'b1;
    end
    default: begin
        nxt_shift = 1'b0;
        nxt_load = 1'b0;
    end
    endcase
end
always @(`SDLIB_CLOCKING) begin
//always @(posedge clk) begin
    shift <= {ctrl_rep{nxt_shift}};
    load <= {ctrl_rep{nxt_load}};
end
// s/drdy signals for control
always @(`SDLIB_CLOCKING) begin
//always @(posedge clk) begin
    case (nxt_state)
    S_0_0:  begin
        c_drdy <= 1'b1;
        p_srdy <= 1'b0;
    end
    S_0_1:  begin
        c_drdy <= 1'b1;  //p_drdy;
        p_srdy <= 1'b1;
    end
    S_1_0:  begin
        c_drdy <= 1'b1;  //p_drdy;
        p_srdy <= 1'b1;
    end
    S_2_1:  begin
        c_drdy <= 1'b0;
        p_srdy <= 1'b1;
    end
    default: begin
        c_drdy <= 1'b0;  //ri lint_check_waive UNREACHABLE
        p_srdy <= 1'b0;	 //ri lint_check_waive UNREACHABLE
    end
    endcase
end
// Data output control
always @(*) begin
    nxt_send_sel  = 1'b0;
    case (nxt_state)
    S_0_1:  begin
        nxt_send_sel  = 1'b0;
    end
    S_1_0:  begin
        nxt_send_sel  = 1'b1;
    end
    S_2_1:  begin
        nxt_send_sel  = 1'b0;
    end
    default: begin
        nxt_send_sel  = 1'b1;
    end
    endcase
end
always @(`SDLIB_CLOCKING) begin
//always @(posedge clk) begin
    send_sel <= {ctrl_rep{nxt_send_sel}};
end


// data path
always @(`SDLIB_CLOCKING) begin
//always @(posedge clk) begin
    for(int g=0;g<ctrl_rep-1;g=g+1) begin
        if(shift[g])  hold_0[g*lfo +: lfo] <= hold_1[g*lfo +: lfo];
        if(load[g])   hold_1[g*lfo +: lfo] <= c_data[g*lfo +: lfo];
    end
    if(shift[ctrl_rep-1])  hold_0[(ctrl_rep-1)*lfo +: hfo] <= hold_1[(ctrl_rep-1)*lfo +: hfo];
    if(load[ctrl_rep-1])   hold_1[(ctrl_rep-1)*lfo +: hfo] <= c_data[(ctrl_rep-1)*lfo +: hfo];
end
always @(*) begin
    for(int g=0;g<ctrl_rep-1;g=g+1) begin
        p_data[g*lfo +: lfo] = send_sel[g] ? hold_1[g*lfo +: lfo] : hold_0[g*lfo +: lfo];
    end
    p_data[(ctrl_rep-1)*lfo +: hfo] = send_sel[ctrl_rep-1] ? hold_1[(ctrl_rep-1)*lfo +: hfo] :
                                                             hold_0[(ctrl_rep-1)*lfo +: hfo] ;
end
endmodule
`endif
