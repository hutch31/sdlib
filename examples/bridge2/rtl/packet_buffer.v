module packet_buffer
  (
   input          clk,
   input          reset,

   input [3:0]    pbra_srdy,
   output [3:0]   pbra_drdy,
   input [`PBR_SZ-1:0] pbra_data_0,            // From p0 of port_macro.v
   input [`PBR_SZ-1:0] pbra_data_1,            // From p1 of port_macro.v
   input [`PBR_SZ-1:0] pbra_data_2,            // From p2 of port_macro.v
   input [`PBR_SZ-1:0] pbra_data_3,            // From p3 of port_macro.v
   input [`PBR_SZ-1:0] pbrd_data_0,            // From p0 of port_macro.v
   input [`PBR_SZ-1:0] pbrd_data_1,            // From p1 of port_macro.v
   input [`PBR_SZ-1:0] pbrd_data_2,            // From p2 of port_macro.v
   input [`PBR_SZ-1:0] pbrd_data_3,            // From p3 of port_macro.v
   input [3:0]    pbrd_srdy,
   output [3:0]   pbrd_drdy,

   output [3:0]   pbrr_srdy,
   input [3:0]    pbrr_drdy,
   output [`PFW_SZ-1:0]  pbrr_data_0,            // To p0 of port_macro.v
   output [`PFW_SZ-1:0]  pbrr_data_1,            // To p1 of port_macro.v
   output [`PFW_SZ-1:0]  pbrr_data_2,            // To p2 of port_macro.v
   output [`PFW_SZ-1:0]  pbrr_data_3             // To p3 of port_macro.v
   
   );

  sd_rrmux #(
              // Parameters
              .width                    (`PBR_SZ),
              .inputs                   (`NUM_PORTS*2),
              .mode                     (0),
              .fast_arb                 (1)) fib_arb
    (
     // Outputs
     .c_drdy                            ({pbra_drdy,pbrd_drdy}), // Templated
     .p_data                            (ppi_data[(`PBR_SZ)-1:0]), // Templated
     .p_grant                           (ppi_grant[(`NUM_PORTS*2)-1:0]), // Templated
     .p_srdy                            (ppi_srdy),              // Templated
     // Inputs
     .clk                               (clk),
     .reset                             (reset),
     .c_data   ({pbra_data_3,pbra_data_2,pbra_data_1,pbra_data_0,
                 pbrd_data_3,pbrd_data_2,pbrd_data_1,pbrd_data_0}),
     .c_srdy                            ({pbra_srdy,pbrd_srdy}), // Templated
     .c_rearb                           (1'b1),
     .p_drdy                            (ppi_drdy));              // Templated
  
  sd_scoreboard #(
                  // Parameters
                  .width                (width),
                  .items                (items),
                  .use_txid             (use_txid),
                  .use_mask             (use_mask),
                  .txid_sz              (txid_sz),
                  .asz                  (asz)) pbmem
    (/*AUTOINST*/
     // Outputs
     .c_drdy                            (c_drdy),
     .p_srdy                            (p_srdy),
     .p_txid                            (p_txid[(txid_sz)-1:0]),
     .p_data                            (p_data[(width)-1:0]),
     // Inputs
     .clk                               (clk),
     .reset                             (reset),
     .c_srdy                            (c_srdy),
     .c_req_type                        (c_req_type),
     .c_txid                            (c_txid[(txid_sz)-1:0]),
     .c_mask                            (c_mask[(width)-1:0]),
     .c_data                            (c_data[(width)-1:0]),
     .c_itemid                          (c_itemid[(asz)-1:0]),
     .p_drdy                            (p_drdy));

endmodule // packet_buffer
// Local Variables:
// verilog-library-directories:("." "../../../rtl/verilog/closure" "../../../rtl/verilog/buffers" "../../../rtl/verilog/utility" "../../../rtl/verilog/forks")
// End:  
