//----------------------------------------------------------------------
//  Author: Heeloo Chung
//  
// 
//----------------------------------------------------------------------
`ifndef _SD_IOFULL_
`define _SD_IOFULL_

module sd_iofull
  #(parameter width = 8,
    parameter isinput = 0)
  (
   input              clk,
   input              reset,
   input              c_srdy,
   output             c_drdy,
   input [width-1:0]  c_data,

   output             p_srdy,
   input              p_drdy,
   output [width-1:0] p_data
   );

  wire                i_irdy, i_drdy;
  wire [width-1:0]    i_data;
  wire                i_srdy;

  generate if (isinput == 1)
    begin : input_config
      sd_output #(width) in
        (
         .ic_drdy                           (c_drdy),
         .p_srdy                            (i_srdy),
         .p_data                            (i_data),
         .clk                               (clk),
         .reset                             (reset),
         .ic_srdy                           (c_srdy),
         .ic_data                           (c_data),
         .p_drdy                            (i_drdy));

      sd_input #(width) out
        (
         .c_drdy                            (i_drdy),
         .ip_srdy                           (p_srdy),
         .ip_data                           (p_data),
         .clk                               (clk),
         .reset                             (reset),
         .c_srdy                            (i_srdy),
         .c_data                            (i_data),
         .ip_drdy                           (p_drdy));
    end
  else
    begin : output_config
      sd_input #(width) in
        (
         .c_drdy                            (c_drdy),
         .ip_srdy                           (i_srdy),
         .ip_data                           (i_data),
         .clk                               (clk),
         .reset                             (reset),
         .c_srdy                            (c_srdy),
         .c_data                            (c_data),
         .ip_drdy                           (i_drdy));
      
      sd_output #(width) out
        (
         .ic_drdy                           (i_drdy),
         .p_srdy                            (p_srdy),
         .p_data                            (p_data),
         .clk                               (clk),
         .reset                             (reset),
         .ic_srdy                           (i_srdy),
         .ic_data                           (i_data),
         .p_drdy                            (p_drdy));
    end // block: output_config
  endgenerate
    
endmodule
`endif
