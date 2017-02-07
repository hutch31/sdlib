//----------------------------------------------------------------------
// Author: Frank Wang
//
// Srdy/Drdy Delayed Flow Control Receiver with flow control override and usage status output.
// This block is optimized for P&R block primary input interface in registered input/output design flow.
//
// Converter block between srdy/drdy protocol and delayed
// flow control (system where srdy and drdy are registered).
// The delay parameter should be set to the combined
// round-trip delay of the system.
//
// Parameters:
//   width : datapath width
//   rt_lat : external round-trip latency from rx.fc_n through tx to rx.vld/data
//   thd : threshold value to begin de-asserting fc_n
//   regcout : flop c_fc_n output
//             when not set, c_fc_n output pin is driven from a OR gate after a comparator
//             The default value minimizes c_fc_n output timing by setting value of 1
//   regcin :   flop c_vld/c_data input
//             when set, input c_vld and c_data is flopped inside this control module.
//             It should usually not be set since sd_fifo_tailwr close timing on the write path.
//   usage_sz: width of usage status output;
//             if usage_sz is less than internal FIFO actual size width, status output saturate at max value.
// FIFO depth requirement is automatically calculated from these parameters.
//
//----------------------------------------------------------------------

`ifndef _SD_DFC_RX_V_
`define _SD_DFC_RX_V_

module sd_dfc_rx #(
    parameter width=8,
    parameter rt_lat=5,
    parameter thd=1,
    parameter regcout=1, //if set, register c_fc_n
    // when set, c_data/vld will be flopped beforing pushing into fifo
    // sd_fifo_tailwr already registers input data, so no need to register USUALLY
    parameter regcin=0,
    // internal FIFO size is calculated in localparameter usz
    parameter usage_sz=3
) (
    input              clk,
    input              rst,
    input              c_vld,
    output logic       c_fc_n,
    input [width-1:0]  c_data,

    input              force_stop,

    output logic             p_srdy,
    input                    p_drdy,
    output logic [width-1:0] p_data,

    output logic                 overflow,
    output logic [usage_sz-1:0]  usage
    /*AUTOINPUT*/
    /*AUTOOUTPUT*/
);

//   depth :  fifo depth,
//            external round_trip latency, plus dfc_rx ctrl delay (regcin + regcout),
//            plus dfc_tx delay (1), plus 1 if using registered fifo.usage
localparam depth=rt_lat + thd + regcout + regcin + 1;
//   usz : fifo usage width
localparam usz = $clog2(depth+1);
/*AUTOLOGIC*/
// Beginning of automatic wires (for undeclared instantiated-module outputs)
logic [width-1:0]       f_data;                 // From u_rx_ctl of sd_dfc_rx_ctl.v
logic                   f_drdy;                 // From u_fifo of sd_fifo_tailwr.v
logic                   f_srdy;                 // From u_rx_ctl of sd_dfc_rx_ctl.v
logic [usz-1:0]         f_usage;                // From u_fifo of sd_fifo_tailwr.v
// End of automatics

// Export usage
generate if (usage_sz >= usz) begin: u_usage_flop_padded0
    always @(posedge clk) begin
        usage          <= {usage_sz{1'b0}};
        usage[usz-1:0] <= f_usage;
    end
end
else begin: u_usage_flop_sat
    always @(posedge clk) begin
        if(f_usage > {usage_sz{1'b1}})begin
            usage <= {usage_sz{1'b1}};
        end else begin
            usage <= f_usage[usage_sz-1:0];
        end
    end
end
endgenerate

/*sd_dfc_rx_ctl AUTO_TEMPLATE (
    .f_pop_vld  (p_srdy && p_drdy),
    .f_\(.*\)   (f_\1[]),
); */
sd_dfc_rx_ctl #(
    .width(width),
    .rt_lat (rt_lat),
    .thd    (thd),
    .regcout(regcout),
    .regcin (regcin),
    .depth  (depth),
    .usz    (usz)
) u_rx_ctl
   (/*AUTOINST*/
    // Outputs
    .c_fc_n                             (c_fc_n),
    .f_srdy                             (f_srdy),                // Templated
    .f_data                             (f_data[width-1:0]),     // Templated
    .overflow                           (overflow),
    // Inputs
    .clk                                (clk),
    .rst                                (rst),
    .force_stop                         (force_stop),
    .c_vld                              (c_vld),
    .c_data                             (c_data[width-1:0]),
    .f_pop_vld                          (p_srdy && p_drdy),      // Templated
    .f_drdy                             (f_drdy),                // Templated
    .f_usage                            (f_usage[usz-1:0]));     // Templated
/* sd_fifo_tailwr AUTO_TEMPLATE (
    .p_usage    (),
    .usage      (f_usage[]),
    .nxt_usage  (),
    .overflow   (),
    .c_\(.*\)   (f_\1[]),
    .reset      (rst),
); */
sd_fifo_tailwr #(
    .width  (width),
    .depth  (depth),
    .usz    (usz)
) u_fifo
   (/*AUTOINST*/
    // Outputs
    .c_drdy                             (f_drdy),                // Templated
    .p_data                             (p_data[width-1:0]),
    .p_srdy                             (p_srdy),
    .nxt_usage                          (),                      // Templated
    .usage                              (f_usage[usz-1:0]),      // Templated
    // Inputs
    .clk                                (clk),
    .reset                              (rst),                   // Templated
    .c_data                             (f_data[width-1:0]),     // Templated
    .c_srdy                             (f_srdy),                // Templated
    .p_drdy                             (p_drdy));

`ifdef SD_INLINE_ASSERTION_ON
logic af_rst_d;
logic af_rst_fell;
logic assert_on;
always @(posedge clk) begin
    af_rst_d <= rst;
    af_rst_fell <= ((af_rst_d === 1'b1) && (rst === 1'b0)) || af_rst_fell;
end
initial begin
    af_rst_fell = 1'b0;
    assert_on=1'b1;
end
ERROR_DFC_RX_OVERFLOW_a: assert property (@(posedge clk)
        disable iff(rst || (~af_rst_fell) || (~assert_on)) (~overflow));
`endif
endmodule
`endif // _SD_DFC_RX_V_
// Local Variables:
// verilog-library-directories:("." "../buffers")
// End:
