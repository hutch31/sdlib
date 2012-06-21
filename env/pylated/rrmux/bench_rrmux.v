module bench_rrmux (input clk, input reset);

  /*AUTOWIRE*/
  // Beginning of automatic wires (for undeclared instantiated-module outputs)
  wire [7:0]            d2f_data;               // From driver0 of dpi_driver.v
  wire                  d2f_drdy;               // From fifo of sd_fifo_s.v
  wire                  d2f_srdy;               // From driver0 of dpi_driver.v
  wire [7:0]            f2m_data;               // From fifo of sd_fifo_s.v
  wire                  f2m_drdy;               // From mon of stupid_mon.v
  wire                  f2m_srdy;               // From fifo of sd_fifo_s.v
  // End of automatics

  initial 
    begin 
      $display("Starting simulation"); 
    end

/* dpi_driver AUTO_TEMPLATE
 (
  .p_\([A-Za-z]+\)         (d2f_\1[]),
 );
*/ 
  dpi_driver #(.width(8), .id(0)) driver0
    (/*AUTOINST*/
     // Outputs
     .p_srdy                            (d2f_srdy),              // Templated
     .p_data                            (d2f_data[7:0]),         // Templated
     // Inputs
     .clk                               (clk),
     .reset                             (reset),
     .p_drdy                            (d2f_drdy));              // Templated

/* sd_fifo_s AUTO_TEMPLATE
 (
  .c_clk (clk),
  .p_clk (clk),
  .c_reset (reset),
  .p_reset (reset),
  .c_\([A-Za-z]+\)         (d2f_\1[]),
  .p_\([A-Za-z]+\)         (f2m_\1[]),
 );
 */
  sd_fifo_s #(.width(8), .depth(16)) fifo
    (/*AUTOINST*/
     // Outputs
     .c_drdy                            (d2f_drdy),              // Templated
     .p_srdy                            (f2m_srdy),              // Templated
     .p_data                            (f2m_data[7:0]),         // Templated
     // Inputs
     .c_clk                             (clk),                   // Templated
     .c_reset                           (reset),                 // Templated
     .c_srdy                            (d2f_srdy),              // Templated
     .c_data                            (d2f_data[7:0]),         // Templated
     .p_clk                             (clk),                   // Templated
     .p_reset                           (reset),                 // Templated
     .p_drdy                            (f2m_drdy));              // Templated

/* stupid_mon AUTO_TEMPLATE
 (
  .c_\([A-Za-z]+\)         (f2m_\1[]),
 );
*/ 
  stupid_mon #(.width(8)) mon
    (/*AUTOINST*/
     // Outputs
     .c_drdy                            (f2m_drdy),              // Templated
     // Inputs
     .clk                               (clk),
     .reset                             (reset),
     .c_srdy                            (f2m_srdy),              // Templated
     .c_data                            (f2m_data[7:0]));         // Templated
  
endmodule
// Local Variables:
// verilog-library-directories:("."  "/home/guy/Proj/sdlib/rtl/verilog/buffers")
// End:
