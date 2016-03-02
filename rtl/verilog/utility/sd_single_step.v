
// Copyright (c) 2012 XPliant, Inc -- All rights reserved
//-----------------------------------------------------------------------------
// sd_single_step.v
// 
// A srdy-drdy shim, that allows to single step the transfers for debug
// purposes. No timing closure is provided.
//
// 
// Author: Gerald Schmidt
// Written: 2013/09/04
//-----------------------------------------------------------------------------

`ifndef SD_SINGLE_STEP_V
  `define SD_SINGLE_STEP_V

// default: posedge clk with async reset
  `ifndef SDLIB_CLOCKING 
    `define SDLIB_CLOCKING posedge clk or posedge rst
  `endif

module sd_single_step 
  #( parameter width = 32,
     parameter tmw   = 8)
  (
   input logic              clk,
   input logic              rst,
   
   input logic              ic_srdy,
   output logic             ic_drdy,
   input logic [width-1:0]  ic_data,
   
   output logic             ip_srdy,
   input logic              ip_drdy,
   output logic [width-1:0] ip_data,
  
   input logic [tmw-1:0]    cfg_timer_start,
   input logic              cfg_en,
   input logic              cfg_step
   );

  logic                     cfg_en_f;
  logic                     cfg_step_f, cfg_step_ff;
  logic                     step_p;
  logic                     enable;
  logic [tmw-1:0]           timr, nxt_timr;
  logic                     timer_en;
  
  always @ (`SDLIB_CLOCKING) begin
    if (rst) begin
      timr        <= cfg_timer_start;
      cfg_en_f    <= 1'b0;
      cfg_step_f  <= 1'b0;
      cfg_step_ff <= 1'b0;
      enable      <= 1'b1;
    end
    else begin
      timr        <= nxt_timr;
      cfg_en_f    <= cfg_en;
      cfg_step_f  <= cfg_step;
      cfg_step_ff <= cfg_step_f;
      enable      <= step_p || !cfg_en_f;
    end
  end // always @ (`SDLIB_CLOCKING)

  always @(*) begin
    if (timr > 0)
      nxt_timr = timr - 1;
    else
      nxt_timr = cfg_timer_start;
  end
  
  assign timer_en = !(cfg_timer_start == 0);
  assign step_p = (cfg_step_f && ! cfg_step_ff) || (timer_en && (timr == 0));
  
  //always @(*) begin
  assign ip_data = ic_data;
  
  assign ip_srdy = ic_srdy && enable;
  assign ic_drdy = ip_drdy && enable;
  
  //if (cfg_en_f) begin
    //  ip_srdy = ic_srdy && step_p;
    //  ic_drdy = ip_drdy && step_p;
    //end
    //else begin
    //  ip_srdy = ic_srdy;
    //  ic_drdy = ip_drdy;
    //end
  //end // always @ (*)

endmodule // sd_delay_match

`endif
