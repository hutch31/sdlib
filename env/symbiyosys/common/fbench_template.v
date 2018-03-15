`define SDLIB_CLOCKING posedge clk
module fbench_$module
 #(parameter width = 16)
 (
  input clk,

  input [width-1:0]   c_data,
  input               c_srdy,
  output              c_drdy,
  output [width-1:0]  p_data,
  output              p_srdy,
  input               p_drdy
 );

  logic reset = 1;
  wire [31:0] in_count, out_count;

  initial
    begin
      assume(reset);
    end

  $module #(.width(width)) dut
    (.clk    (clk), 
     .reset  (reset),
     .${cons}_srdy (c_srdy),
     .${cons}_drdy (c_drdy),
     .${cons}_data (c_data),
     .${prod}_srdy (p_srdy),
     .${prod}_drdy (p_drdy),
     .${prod}_data (p_data)
    );

  sd_common_checks #(.width(width)) common
    (.clk    (clk), 
     .reset  (reset),
     .c_srdy (c_srdy),
     .c_drdy (c_drdy),
     .c_data (c_data),
     .p_srdy (p_srdy),
     .p_drdy (p_drdy),
     .p_data (p_data),

     .in_count (in_count),
     .out_count (out_count));

endmodule

