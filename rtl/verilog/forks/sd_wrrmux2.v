//----------------------------------------------------------------------
// Srdy/drdy 2-input weighted-round-robin arbiter
//
// Naming convention: c = consumer, p = producer, i = internal interface
//----------------------------------------------------------------------
//  Author: Frank Wang
//
// This block is uncopyrighted and released into the public domain.
//----------------------------------------------------------------------
`ifndef SD_WRRMUX2_TP_V
`define SD_WRRMUX2_TP_V
// Clocking statement for synchronous blocks.  Default is for
// posedge clocking and positive async reset
`ifndef SDLIB_CLOCKING 
 `define SDLIB_CLOCKING posedge clk or posedge reset
`endif

module sd_wrrmux2 #(
    parameter width=8,
    parameter weight_sz=2
)(
   input               clk,
   input               reset,
  
   input logic [(width*2)-1:0] c_data,
   input logic [weight_sz*2-1:0] c_weight,
   input logic [2-1:0]      c_srdy,
   output  logic [2-1:0]    c_drdy,

   output logic [width-1:0]  p_data,
   output logic [2-1:0]     p_grant,
   output logic             p_srdy,
   input                   p_drdy
);

reg [1:0][weight_sz-1:0] w_cnt;
reg [1:0][weight_sz-1:0] nxt_w_cnt;
reg [1:0]                i_grant; //which source is granted internally.

// state: weight
always @(*) begin
    nxt_w_cnt = w_cnt;
    if(p_grant[1]) begin
        /*if((w_cnt[0] >= c_weight[0 +: weight_sz]) && 
                    (c_weight[weight_sz +: weight_sz] < 2)) begin
            nxt_w_cnt[1] = {weight_sz{1'b0}};
            nxt_w_cnt[0] = {weight_sz{1'b0}};
        end else */ if((w_cnt[0] >= c_weight[0 +: weight_sz]) && 
                    (w_cnt[1] >= c_weight[weight_sz +: weight_sz]-1)) begin
            nxt_w_cnt[1] = {weight_sz{1'b0}};
            nxt_w_cnt[0] = {weight_sz{1'b0}};
        /*end else if (c_weight[weight_sz +: weight_sz]<2) begin
            nxt_w_cnt[1] = 1;
        */end else if (w_cnt[1] < c_weight[weight_sz +: weight_sz]) begin
            nxt_w_cnt[1] = w_cnt[1] + 1;
        end
    end else if(p_grant[0]) begin
        /*if((w_cnt[0] >= c_weight[0 +: weight_sz]-2) && 
                    (c_weight[0 +: weight_sz] < 2)) begin
            nxt_w_cnt[1] = {weight_sz{1'b0}};
            nxt_w_cnt[0] = {weight_sz{1'b0}};
        end else */ if((w_cnt[0] >= c_weight[0 +: weight_sz]-1) && 
                    (w_cnt[1] >= c_weight[weight_sz +: weight_sz])) begin
            nxt_w_cnt[1] = {weight_sz{1'b0}};
            nxt_w_cnt[0] = {weight_sz{1'b0}};
        /*end else if (c_weight[0 +: weight_sz]<2) begin
            nxt_w_cnt[0] = 1;
        */end else if (w_cnt[0] < c_weight[0 +: weight_sz]) begin
            nxt_w_cnt[0] = w_cnt[0] + 1;
        end
    end
end
always @(`SDLIB_CLOCKING ) begin
    if(reset) begin
        for(int i=0;i<2;i=i+1) begin
            w_cnt[i] <= {weight_sz{1'b0}};
        end
    end else begin
        for(int i=0;i<2;i=i+1) begin
            w_cnt[i] <= nxt_w_cnt[i];
        end
    end
end

// state: if a c_srdy is asserted, p_drdy is not, then p_data need to stay stable 
logic [1:0] grant_blk;
always @(`SDLIB_CLOCKING) begin
    if(reset) begin
        grant_blk <= 2'b0;
    end else begin
        for(int i=0;i<2;i=i+1) begin
            grant_blk[i] <= i_grant[i] & (~p_drdy);
        end
    end
end

// select p_data
always @(*) begin
    case (c_srdy) 
    2'b00: begin
        c_drdy = 2'b0;
        p_srdy = 1'b0;
        p_data = c_data[0 +: width];
        i_grant = 2'b00;
    end
    2'b01: begin
        c_drdy = {1'b0,p_drdy};
        p_srdy = 1'b1;
        p_data = c_data[0 +: width];
        i_grant = 2'b01;
    end
    2'b10: begin
        c_drdy = {p_drdy,1'b0};
        p_srdy = 1'b1;
        p_data = c_data[width +: width];
        i_grant = 2'b10;
    end
    2'b11: begin
        if(grant_blk[1]) begin // last grant[1] hasn't go through yet.
            c_drdy = {p_drdy,1'b0};
            p_srdy = 1'b1;
            p_data = c_data[width +: width];
            i_grant = 2'b10;
        end else if(grant_blk[0]) begin // last grant[0] hasn't go through yet.
            c_drdy = {1'b0,p_drdy};
            p_srdy = 1'b1;
            p_data = c_data[0 +: width];
            i_grant = 2'b01;
        end else if(w_cnt[0] < c_weight[0 +: weight_sz]) begin // select 0
            c_drdy = {1'b0,p_drdy};
            p_srdy = 1'b1;
            p_data = c_data[0 +: width];
            i_grant = 2'b01;
        end else begin // select 1
            c_drdy = {p_drdy,1'b0};
            p_srdy = 1'b1;
            p_data = c_data[width +: width];
            i_grant = 2'b10;
        end
    end
    endcase
end
assign p_grant = c_drdy;

endmodule 
`endif //  SD_WRRMUX2_TP_V
