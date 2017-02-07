//----------------------------------------------------------------------
// Author: Frank Wang
//
// Srdy/Drdy Delayed Flow Control Transmitter with rate control capability
//
// Converter block between srdy/drdy protocol and delayed
// flow control (system where srdy and drdy are registered).
//
// DFC protocol requirement: stop sending traffic one cycle after p_fc_n goes low, in SVA
//          (p_vld) |-> $past(p_fc_n)
//
// This DFC TX incorportate rate control capability, for every "window_size"
//          clock cycles, it allow maximum "rc_max_tx" transactions; additionally,
//          for every "window_size" clock cycles, if number of clock cycle where the TX
//          has data to send but is being flow controlled (i.e. c_srdy && ~p_fc_n) exceeds
//          "mon_fc_thd" cycles, sd_dfc_rxtc asserts mon_triggered for remainder of the window.
//
// Parameters:
//  regpin: register input p_fc_n
//  regpout: regsiter output p_vld and p_data, note the p_vld signal still goes through one combo gate
//          for normal operations, both regpin and regpout shall not be modified.
//  rc_ctr_sz: counter width for the time window counter, it determins the gralularity of rate control
//          when rc_ctr_sz=8, minimal granularity is 1/255, i.e. ~0.4%
//----------------------------------------------------------------------

`ifndef _SD_DFC_RCTX_V_
`define _SD_DFC_RCTX_V_

module sd_dfc_rctx #(
    parameter rc_ctr_sz =8, // default rate granularity is 1/255, i.e. ~0.4%
    parameter width=8,
    parameter regpin=1, // if set, register input p_fc_n
    parameter regpout=1 // if regpin==0 && regpout==0, then p_vld and p_data are registered.
) (
    // input pins for rate control and/or monitoring, recommended to be tied to cfg slave
    input   logic   [rc_ctr_sz-1:0]    window_size,
    input   logic   [rc_ctr_sz-1:0]    rc_max_tx,
    input   logic   [rc_ctr_sz-1:0]    mon_fc_thd,
    output  logic                      mon_triggered, // connect to cfg slave interrupt register

    input logic [width-1:0]  c_data,
    input logic              c_srdy,
    output logic             c_drdy,

    output logic [width-1:0] p_data,
    output logic             p_vld,
    input logic              p_fc_n,

    input logic              clk,
    input logic              rst
);

/*AUTOLOGIC*/
logic [rc_ctr_sz-1:0] nxt_window_ctr, window_ctr;
logic [rc_ctr_sz-1:0] nxt_tx_ctr, tx_ctr;
logic [rc_ctr_sz-1:0] nxt_fc_ctr, fc_ctr;
logic                 in_progress;
logic                 force_stop;
always @(posedge clk) begin
    /* if(c_srdy && c_drdy) */
        in_progress <= 1'b1;
    if(rst)              in_progress <= 1'b0;
end
always @(*) begin
    nxt_window_ctr = window_ctr + 1'b1;
    if(nxt_window_ctr >= window_size)   nxt_window_ctr = {rc_ctr_sz{1'b0}};

    nxt_tx_ctr = tx_ctr + (c_srdy && c_drdy);  //ri lint_check_waive RHS_TOO_SHORT
    nxt_fc_ctr = fc_ctr + (c_srdy && ~c_drdy); //ri lint_check_waive RHS_TOO_SHORT
    if(nxt_window_ctr == {rc_ctr_sz{1'b0}}) begin
        nxt_tx_ctr    = {rc_ctr_sz{1'b0}};
        nxt_tx_ctr[0] = (c_srdy && c_drdy); // to make linting happy
        nxt_fc_ctr    = {rc_ctr_sz{1'b0}};
        nxt_fc_ctr[0] = (c_srdy && ~c_drdy); // to make linting happy
    end
end
always @(posedge clk) begin
    window_ctr <= nxt_window_ctr;
    tx_ctr  <= nxt_tx_ctr;
    fc_ctr  <= nxt_fc_ctr;
    if(~in_progress) begin
        window_ctr <= window_size;
        tx_ctr  <= {rc_ctr_sz{1'b0}};
        fc_ctr  <= {rc_ctr_sz{1'b0}};
    end

    force_stop <= (nxt_tx_ctr >= rc_max_tx) && in_progress && (nxt_window_ctr >= rc_max_tx);
    mon_triggered <= (nxt_fc_ctr > mon_fc_thd) && (nxt_window_ctr >= mon_fc_thd);
end

logic   ic_srdy;
logic   ic_drdy;
/*dfc_sender AUTO_TEMPLATE (
    .f_\(.*\)   (f_\1[]),
    .reset      (rst),
    .c_srdy     (ic_srdy),
    .c_drdy     (ic_drdy),
    .p_fc_n     (p_fc_n),
); */
generate if((regpin >0) && (regpout >0) ) begin : reg_in_out
    logic [width-1:0]   ic_data;
    always @(posedge clk) begin
        if(rst) begin
            ic_drdy <= 1'b0;
        end else begin
            ic_drdy <= p_fc_n;
        end
    end
    assign p_vld = ic_srdy && ic_drdy && (~ force_stop);
    assign p_data = ic_data;
    sd_output   #(.width(width)) u_reg_in (
        .clk(clk), .reset(rst),
        .ic_srdy(c_srdy), .ic_drdy(c_drdy), .ic_data(c_data),
        .p_srdy(ic_srdy), .p_drdy(ic_drdy && (~ force_stop)), .p_data(ic_data)
    );
end else if (regpin > 0) begin: reg_p_fc_n
    always @(posedge clk) begin
        if(rst) begin
            ic_drdy <= 1'b0;
        end else begin
            ic_drdy <= p_fc_n && (~force_stop);
        end
    end
    assign p_vld = ic_srdy && ic_drdy;
    assign p_data = c_data;
    assign c_drdy = ic_drdy && (~force_stop);
    assign ic_srdy = c_srdy && (~force_stop);
end else begin : reg_p_vld
    dfc_sender #(
        .width(width)
    ) u_tx
       (/*AUTOINST*/
        // Outputs
        .c_drdy                         (ic_drdy),               // Templated
        .p_vld                          (p_vld),
        .p_data                         (p_data[width-1:0]),
        // Inputs
        .clk                            (clk),
        .reset                          (rst),                   // Templated
        .c_srdy                         (ic_srdy),               // Templated
        .c_data                         (c_data[width-1:0]),
        .p_fc_n                         (p_fc_n));               // Templated
        assign ic_srdy = c_srdy && (~force_stop);
        assign c_drdy = ic_drdy && (~force_stop);
end
endgenerate

`ifdef SIMULATION
    `ifndef SD_INLINE_ASSERTION_OFF // these assertions are by default on in simulation
logic assert_on;
initial begin
    assert_on=1'b1;
end
ERROR_DFC_TX_VLD_a: assert property (@(posedge clk)
        disable iff(rst || (~assert_on)) (p_vld |-> $past(p_fc_n)));
    `endif
`endif
endmodule
`endif //_SD_DFC_RCTX_V_
// Local Variables:
// verilog-library-directories:("." "../closure")
// End:
