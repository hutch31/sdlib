`define TEST_FIFO_C
module wrap_fifo_c
  #(parameter depth=6, parameter usz=$clog2(depth+1))
  (/*AUTOINPUT*/
  // Beginning of automatic inputs (from unused autoinst inputs)
  input [7:0]           c_data,                 // To finst of sd_fifo_c.v, ...
  input                 c_srdy,                 // To finst of sd_fifo_c.v, ...
  input                 clk,                    // To finst of sd_fifo_c.v, ...
  input                 p_drdy,                 // To finst of sd_fifo_c.v, ...
  input                 reset,                  // To finst of sd_fifo_c.v, ...
  // End of automatics
   /*AUTOOUTPUT*/
   // Beginning of automatic outputs (from unused autoinst outputs)
   output               c_drdy,                 // From finst of sd_fifo_c.v, ...
   output [7:0]         p_data,                 // From finst of sd_fifo_c.v, ...
   output logic         p_srdy,                 // From finst of sd_fifo_c.v, ...
   output logic [usz-1:0] usage                // From finst of sd_fifo_c.v
   // End of automatics
   );

  localparam width = 8;

`ifdef TEST_FIFO_C
  sd_fifo_c #(// Parameters
              .width                    (8),
              .depth                    (depth))
  finst
    (/*AUTOINST*/
     // Outputs
     .c_drdy                            (c_drdy),
     .usage                             (usage[usz-1:0]),
     .p_srdy                            (p_srdy),
     .p_data                            (p_data[7:0]),
     // Inputs
     .clk                               (clk),
     .reset                             (reset),
     .c_srdy                            (c_srdy),
     .c_data                            (c_data[7:0]),
     .p_drdy                            (p_drdy));
`endif //  `ifdef TEST_FIFO_C

`ifdef TEST_IOFULL
  sd_iofull #(.width(8), .isinput(1))
  iofull
    (/*AUTOINST*/
     // Outputs
     .c_drdy                            (c_drdy),
     .p_srdy                            (p_srdy),
     .p_data                            (p_data[7:0]),
     // Inputs
     .clk                               (clk),
     .reset                             (reset),
     .c_srdy                            (c_srdy),
     .c_data                            (c_data[7:0]),
     .p_drdy                            (p_drdy));
`endif

  logic [7:0]             pop_data;
  logic                   pop_valid;
  
  fv_fifo #(
            // Parameters
            .width                      (8),
            .depth                      (depth))
  chk_fifo
    (
     // Outputs
     .pop_data                          (pop_data[7:0]),
     .pop_valid                         (pop_valid),
     // Inputs
     .clk                               (clk),
     .reset                             (reset),
     .push                              (c_srdy & c_drdy),
     .push_data                         (c_data),
     .pop                               (p_srdy & p_drdy));

  // usage checker
  logic [usz-1:0]         shadow_usage;

  always @(posedge clk)
    begin
      if (reset)
        shadow_usage <= 0;
      else if (c_srdy & c_drdy & (!p_srdy | !p_drdy))
        shadow_usage <= shadow_usage + 1;
      else if (p_srdy & p_drdy & (!c_srdy | !c_drdy))
        shadow_usage <= shadow_usage - 1;
    end

`ifdef TEST_FIFO_C
  CountEqual_a: assert property (@(posedge clk) disable iff(reset) (shadow_usage == usage));
`endif

  DataEqual_a: assert property (@(posedge clk) disable iff(reset) (p_srdy & p_drdy) |-> (p_data == pop_data));
  
endmodule // wrap_fifo_c
// Local Variables:
// verilog-library-directories:("." "../common" "../../../rtl/verilog/closure" "../../../rtl/verilog/buffers")
// End:
