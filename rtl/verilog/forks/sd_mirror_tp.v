//----------------------------------------------------------------------
//  pin-compatible with sd_mirror, except that there is no flopping inside
//
//----------------------------------------------------------------------
//  Author: Frank Wang
//
//----------------------------------------------------------------------
`ifndef SD_MIRROR_TP_V
`define SD_MIRROR_TP_V
`ifdef SDLIB_CLOCKING
`else
 `define SDLIB_CLOCKING posedge clk or posedge reset
`endif
module sd_mirror_tp
#(  parameter mirror=2,
    parameter width=8
)(
    input        clk,
    input        reset,

    input              c_srdy,
    output logic       c_drdy,
    input [width-1:0]  c_data,
    input [mirror-1:0] c_dst_vld,

    output logic [mirror-1:0] p_srdy,
    input  logic [mirror-1:0] p_drdy,
    output logic [width-1:0]  p_data
);

logic [mirror-1:0]   p_blk_st; // a 1 means this output is causing blocking because of p_drdy bit
logic [mirror-1:0]   nxt_p_blk_st;

logic [mirror-1:0][mirror-1:0]   p_blk_st_masked; //my own block state is masked, i.e.this[i][i]=0.
logic [mirror-1:0]   other_to_blame;  // it's someone else blocking, but not me

// is it someone else responsible for blocking, and am I innocent?
always @(*) begin
    for(int i=0;i<mirror;i=i+1) begin
        p_blk_st_masked[i][mirror-1:0] = p_blk_st[mirror-1:0];
        p_blk_st_masked[i][i] = 1'b0;

        other_to_blame[i] = (| p_blk_st_masked[i][mirror-1:0]) & 
               ((~p_blk_st[i]) | (~c_dst_vld[i]));
    end
end

// next state calculation
always @(*) begin
    for(int i=0;i<mirror;i=i+1) begin
        if(other_to_blame[i]) nxt_p_blk_st[i] = 1'b0;
        else    nxt_p_blk_st[i] = c_srdy & c_dst_vld[i] & (~p_drdy[i]);
    end
end

// state update
always @(`SDLIB_CLOCKING)begin
    if(reset)begin
        p_blk_st <= {mirror{1'b0}};
    end else begin
        p_blk_st <= nxt_p_blk_st;
    end
end

// external facing stuff
always @(*) begin
    p_data = c_data;
    
    for(int i=0;i<mirror;i=i+1) begin
        if(other_to_blame[i]) p_srdy[i] = 1'b0; // do not over-cook 
        else    p_srdy[i] = c_srdy & c_dst_vld[i];
    end
end
// c_drdy:
// (1) if all intended destination are ready to accept
// or (2) if currently in blocking state, and all those blocking are ready to accept
always @(*) begin
    logic in_blk_st;
    logic all_blk_dest_rdy;
    logic all_dest_rdy;

    in_blk_st = | p_blk_st;
    all_blk_dest_rdy = in_blk_st && (&( (~p_blk_st) | p_drdy ));
    all_dest_rdy = & (p_drdy | (~ c_dst_vld));

    c_drdy = all_dest_rdy | all_blk_dest_rdy;
end



endmodule 
`endif // SD_MIRROR_TP_V
