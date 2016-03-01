//----------------------------------------------------------------------
// Srdy/drdy round-robin arbiter, pin compatible with sd_rrmux, 
// but without the one cycle decision delay.
//
// Naming convention: c = consumer, p = producer, i = internal interface
//----------------------------------------------------------------------
//  Author: Frank Wang
//
// This block is uncopyrighted and released into the public domain.
//----------------------------------------------------------------------
`ifndef _SD_PRIO_RRMUX_V_
`define _SD_PRIO_RRMUX_V_
// Clocking statement for synchronous blocks.  Default is for
// posedge clocking and positive async reset
`ifndef SDLIB_CLOCKING 
 `define SDLIB_CLOCKING posedge clk or posedge reset
`endif

// delay unit for nonblocking assigns, default is to #1 
`ifndef SDLIB_DELAY 
 `define SDLIB_DELAY #1  
`endif

module sd_prio_rrmux
  #(parameter width=8,
    parameter inputs=2,
    parameter mode=0,
    parameter fast_arb=1,
    parameter prio_width=4)
  (
   input               clk,
   input               reset,
  
   input [(width*inputs)-1:0] c_data,
   input [inputs-1:0]      c_srdy,
   output  [inputs-1:0]    c_drdy,
   input                   c_rearb,  // for use with mode 2 only

   output reg [width-1:0]  p_data,
   output [inputs-1:0]     p_grant,
   output reg              p_srdy,
   input                   p_drdy,

   // 

   input [(prio_width*inputs)-1:0] prio,
   input [inputs-1:0]              mask

   );
  

  localparam prio_levels = 1 << prio_width;
  genvar               i;
  integer              j;

  reg [prio_width-1:0] max_prio_val;
  reg [prio_width-1:0] prio_val[inputs-1:0];
  reg [inputs-1:0]     c_srdy_mask;

  always @* begin
    for(j=0;j<inputs;j++) begin
      prio_val[j] = prio >> (prio_width * j);
    end
    // find the max prio value   FIXME: maybe this is not synthetizable ?
    max_prio_val = 0;
    for(j=0;j<inputs;j++) begin
      if (mask[j] && c_srdy[j] && (prio_val[j] > max_prio_val)) begin
        max_prio_val = prio_val[j];
      end
    end
    // generate c_srdy_mask
    for(j=0;j<inputs;j++) begin
      c_srdy_mask[j] = mask[j] & c_srdy[j] & ((prio_val[j] == max_prio_val) ? 1'b1 : 1'b0);
    end
  end


  // bmp for the c_srdy that has just been granted and accepted by p_drdy
  reg [prio_levels-1:0][inputs-1:0]    just_granted;
  //control path, transit only after p_drdy ("accepted" part).
  reg [inputs-1:0]    to_be_granted; 
  //for data path, regardless of p_drdy, help to remove combo loops
  //rational being, when p_drdy==1'b0, it doesn't matter what p_data is.
  reg [inputs-1:0]    to_tx_data; 

  wire [width-1:0]     rr_mux_grid [0:inputs-1];
  reg 		       rr_locked;
  reg nxt_rr_locked; // ri lint_check_waive NOT_DRIVEN

  assign c_drdy = to_be_granted & {inputs{p_drdy}};
  assign p_grant = to_be_granted;

  function [inputs-1:0] nxt_grant;
    input [inputs-1:0] cur_grant;
    input [inputs-1:0] cur_req;
    input              cur_accept;
    reg [inputs-1:0]   msk_req;
    reg [inputs-1:0]   tmp_grant;
    reg [inputs-1:0]   tmp_grant2;

    begin
// scenario: 
// in cycle 0, src 1 is granted and accepted by p_drdy,
// in cycle 1, src 3 is requesting, but p_drdy is 0, so c_data3 is presented at p_data with p_srdy
// in cycle 2, if src 2 comes in requesting, should hold src 3 at p_data till p_drdy, 
//             src 2 will only participate in next round arb.
// the way is in this scenario, pretend src2 is the just_granted in cycle 1.
// so arbitration is excercies in two cases: (1): p_drdy, 
// or (2) p_not_drdy, the immediate next c_not_srdy, but at least one remote c_srdy
      
      msk_req = cur_req & ~((cur_grant - 1) | cur_grant);
      tmp_grant = msk_req & (~msk_req + 1);
      tmp_grant2 = cur_req & (~cur_req + 1);

      if(cur_accept)begin
          if (msk_req != 0) nxt_grant = tmp_grant;
          else nxt_grant = tmp_grant2;
      //end else if (rem_neighbor_rearb) begin
      end else if (| cur_req) begin
          if (msk_req != 0) nxt_grant = {tmp_grant[0],tmp_grant[inputs-1:1]};
          else nxt_grant = {tmp_grant2[0],tmp_grant2[inputs-1:1]};
      end else begin
          nxt_grant = cur_grant;
      end
    end
  endfunction
  
  generate
    for (i=0; i<inputs; i=i+1)
      begin : grid_assign
        //assign rr_mux_grid[i] = c_data >> (i*width);
        assign rr_mux_grid[i] = c_data[i*width+width-1 : i*width]; 
      end

    if (mode == 2)
      begin : tp_gen
        always @*
          begin
            nxt_rr_locked = rr_locked;

            if ((c_srdy_mask & just_granted) & (!rr_locked))
              nxt_rr_locked = 1;
            else if ((c_srdy_mask & just_granted & c_rearb))
              nxt_rr_locked = 0;
          end

        always @(`SDLIB_CLOCKING)
          begin
            if (reset)
              rr_locked <= 0;
            else
              rr_locked <= nxt_rr_locked;
          end
      end // block: tp_gen
  endgenerate

//  always @*
//    begin
//      p_data = 0;
//      p_srdy = 0;
//      for (j=0; j<inputs; j=j+1)
//        if (just_granted[j])
//          begin
//            p_data = rr_mux_grid[j];
//            p_srdy = c_srdy[j];
//          end
//    end
always @(*) begin
    p_srdy = | c_srdy_mask;

    p_data = {width{1'b0}};
    for (j=0; j<inputs; j=j+1) begin
        if (to_tx_data[j]) begin
            p_data = rr_mux_grid[j];
            p_srdy = c_srdy_mask[j];
        end
    end
end
  
  always @*
    begin
      to_tx_data = just_granted[max_prio_val];
      to_be_granted = just_granted[max_prio_val];
      if ((mode ==  1) & (|(c_srdy_mask & just_granted[max_prio_val])))
        to_be_granted = just_granted[max_prio_val];
      else if ((mode == 0) && !fast_arb)begin
        to_be_granted=p_drdy?{just_granted[max_prio_val][0],just_granted[max_prio_val][inputs-1:1]}:just_granted[max_prio_val];
        to_tx_data={just_granted[max_prio_val][0],just_granted[max_prio_val][inputs-1:1]};
      end
      //else if ((mode == 0) && |(just_granted & c_srdy) && !p_drdy && fast_arb)
      //  to_be_granted = just_granted;
      else if ((mode == 2) & (nxt_rr_locked | (|(c_srdy_mask & just_granted[max_prio_val]))))
        to_be_granted = just_granted[max_prio_val];
      else if (fast_arb) begin
        to_be_granted=nxt_grant (just_granted[max_prio_val], c_srdy_mask, p_drdy);
        to_tx_data = nxt_grant(just_granted[max_prio_val], c_srdy_mask, 1'b1);
      end
      else begin
        to_be_granted=p_drdy?{just_granted[max_prio_val][0],just_granted[max_prio_val][inputs-1:1]}:just_granted[max_prio_val];
        to_tx_data={just_granted[max_prio_val][0],just_granted[max_prio_val][inputs-1:1]};
      end
    end

  always @(`SDLIB_CLOCKING)
    begin
      for (j=0; j<prio_levels; j++) begin
        if (reset)
          just_granted[j] <= {1'b1,{inputs-1{1'b0}}};
        else
          if (to_be_granted==0)
            just_granted[j] <= just_granted[j];
          else
            if (j==max_prio_val)
              just_granted[j] <= to_be_granted;
            else 
              just_granted[j] <= just_granted[j];
      end
    end

endmodule // 
`endif //  
