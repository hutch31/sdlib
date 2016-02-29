//----------------------------------------------------------------------
// Author: Frank Wang
// 
// De-serialize narrower data in multiple cycles into wider parallel data.
//
//----------------------------------------------------------------------
`ifndef _SD_DESERIALIZER_V_
`define _SD_DESERIALIZER_V_
module sd_deserializer #(
    parameter int PARA_WIDTH=63,
    parameter int SER_WIDTH=8
) (
    input   logic [SER_WIDTH-1:0]  c_data,
    input   logic                  c_ef,
    input   logic                  c_srdy,
    output  logic                  c_drdy,

    output  logic [PARA_WIDTH-1:0] p_data,
    output  logic                  p_srdy,
    input   logic                  p_drdy,

    input   clk,
    input   reset
);

localparam NUM_SEG_FLOOR = (PARA_WIDTH/SER_WIDTH);
localparam NUM_SEG=(NUM_SEG_FLOOR*SER_WIDTH == PARA_WIDTH) ? NUM_SEG_FLOOR : NUM_SEG_FLOOR+1;
localparam LAST_SEG_WIDTH = (NUM_SEG_FLOOR*SER_WIDTH == PARA_WIDTH) ? SER_WIDTH : (PARA_WIDTH - NUM_SEG_FLOOR*SER_WIDTH);
localparam SEG_SZ = $clog2(NUM_SEG);
//
//logic [SEG_SZ-1:0]  st_seg_num;
//logic [SEG_SZ-1:0]  nxt_st_seg_num;


logic [NUM_SEG * SER_WIDTH-1:0] hold_data;
logic [NUM_SEG * SER_WIDTH-1:0] nxt_hold_data;
logic [SEG_SZ-1:0] seg_num;
logic [SEG_SZ-1:0] nxt_seg_num;

always @(posedge clk) begin
    hold_data <= nxt_hold_data;
    seg_num  <= nxt_seg_num;
    if(reset)   seg_num  <= {SEG_SZ{1'b0}};
end

assign p_srdy = c_srdy && c_ef;
assign p_data = nxt_hold_data;
assign c_drdy = (c_srdy && ~c_ef) || (c_srdy && c_ef && p_drdy);

always @(*) begin
    nxt_seg_num = seg_num;
    if(c_srdy && c_drdy && c_ef) nxt_seg_num = {SEG_SZ{1'b0}};
    else if(c_srdy && c_drdy)    nxt_seg_num = seg_num + 1'b1;
end
always @(*) begin
    nxt_hold_data = hold_data;
    for(int i=0; i<NUM_SEG; i++)begin
        if(c_srdy && c_drdy && (i == seg_num))
            nxt_hold_data[i * SER_WIDTH +: SER_WIDTH] = c_data;
    end
end

endmodule 
// Local Variables:
// End:
`endif //  _SD_DESERIALIZER_V_
