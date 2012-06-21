module bench_rrmux (input clk, input reset);

  /*AUTOWIRE*/
  // Beginning of automatic wires (for undeclared instantiated-module outputs)
  wire [31:0]           in_data;                // From gen0 of dpi_driver.v, ...
  wire [3:0]            in_drdy;                // From rrmux of sd_rrmux.v
  wire [3:0]            in_srdy;                // From gen0 of dpi_driver.v, ...
  wire [7:0]            mm_data;                // From rrmux of sd_rrmux.v
  wire                  mm_drdy;                // From mirror of sd_mirror.v
  wire                  mm_srdy;                // From rrmux of sd_rrmux.v
  wire [7:0]            out_data;               // From mirror of sd_mirror.v
  wire [3:0]            out_drdy;               // From check0 of stupid_mon.v, ...
  wire [3:0]            out_srdy;               // From mirror of sd_mirror.v
  // End of automatics

/* dpi_driver AUTO_TEMPLATE
 (
     .width (8),
     .id (@),
     .p_srdy                            (in_srdy[@]),
     .p_drdy                            (in_drdy[@]),
     .p_data                            (in_data[@"(+ 7 (* @ 8))":@"(* @ 8)"]),
 );
 */
  dpi_driver #(/*AUTOINSTPARAM*/
               // Parameters
               .width                   (8),                     // Templated
               .id                      (0))                     // Templated
  gen0
    (/*AUTOINST*/
     // Outputs
     .p_srdy                            (in_srdy[0]),            // Templated
     .p_data                            (in_data[7:0]),          // Templated
     // Inputs
     .clk                               (clk),
     .reset                             (reset),
     .p_drdy                            (in_drdy[0]));            // Templated
  
  dpi_driver #(/*AUTOINSTPARAM*/
               // Parameters
               .width                   (8),                     // Templated
               .id                      (1))                     // Templated
  gen1
    (/*AUTOINST*/
     // Outputs
     .p_srdy                            (in_srdy[1]),            // Templated
     .p_data                            (in_data[15:8]),         // Templated
     // Inputs
     .clk                               (clk),
     .reset                             (reset),
     .p_drdy                            (in_drdy[1]));            // Templated
  
  dpi_driver #(/*AUTOINSTPARAM*/
               // Parameters
               .width                   (8),                     // Templated
               .id                      (2))                     // Templated
  gen2
    (/*AUTOINST*/
     // Outputs
     .p_srdy                            (in_srdy[2]),            // Templated
     .p_data                            (in_data[23:16]),        // Templated
     // Inputs
     .clk                               (clk),
     .reset                             (reset),
     .p_drdy                            (in_drdy[2]));            // Templated
  
  dpi_driver #(/*AUTOINSTPARAM*/
               // Parameters
               .width                   (8),                     // Templated
               .id                      (3))                     // Templated
  gen3
    (/*AUTOINST*/
     // Outputs
     .p_srdy                            (in_srdy[3]),            // Templated
     .p_data                            (in_data[31:24]),        // Templated
     // Inputs
     .clk                               (clk),
     .reset                             (reset),
     .p_drdy                            (in_drdy[3]));            // Templated
  
 /* sd_rrmux AUTO_TEMPLATE
 (
     .c_drdy                            (in_drdy[3:0]),
     .c_data                            (in_data[(8*4)-1:0]),
     .c_srdy                            (in_srdy[]),
     .c_rearb                           (1'b1),
  
     .p_data                            (mm_data[7:0]),
     .p_grant                           (),
     .p_srdy                            (mm_srdy),
     .p_drdy                            (mm_drdy),
   );
  */
  sd_rrmux #(
             // Parameters
             .width                     (8),
             .inputs                    (4),
             .mode                      (0),
             .fast_arb                  (1)) rrmux
    (/*AUTOINST*/
     // Outputs
     .c_drdy                            (in_drdy[3:0]),          // Templated
     .p_data                            (mm_data[7:0]),          // Templated
     .p_grant                           (),                      // Templated
     .p_srdy                            (mm_srdy),               // Templated
     // Inputs
     .clk                               (clk),
     .reset                             (reset),
     .c_data                            (in_data[(8*4)-1:0]),    // Templated
     .c_srdy                            (in_srdy[3:0]),          // Templated
     .c_rearb                           (1'b1),                  // Templated
     .p_drdy                            (mm_drdy));               // Templated

  wire [3:0] mm_dst_vld;
  assign mm_dst_vld = 1 << mm_data[7:6];
  
/* sd_mirror AUTO_TEMPLATE
 (
     .c_data                            (mm_data[]),
     .c_srdy                            (mm_srdy),
     .c_drdy                            (mm_drdy),
     .c_dst_vld                         (mm_dst_vld[]),
     .p_srdy                            (out_srdy[]),
     .p_data                            (out_data[]),
     .p_drdy                            (out_drdy[])); 
 );
 */
  sd_mirror #(
              // Parameters
              .mirror                   (4),
              .width                    (8))  mirror
    (/*AUTOINST*/
     // Outputs
     .c_drdy                            (mm_drdy),               // Templated
     .p_srdy                            (out_srdy[3:0]),         // Templated
     .p_data                            (out_data[7:0]),         // Templated
     // Inputs
     .clk                               (clk),
     .reset                             (reset),
     .c_srdy                            (mm_srdy),               // Templated
     .c_data                            (mm_data[7:0]),          // Templated
     .c_dst_vld                         (mm_dst_vld[3:0]),       // Templated
     .p_drdy                            (out_drdy[3:0]));         // Templated

  
/* stupid_mon AUTO_TEMPLATE
 (
     .width (8),
     .id (@+4),
     .c_srdy                            (out_srdy[@]),
     .c_drdy                            (out_drdy[@]),
     .c_data                            (out_data[7:0]),
 );
 */
  stupid_mon #(/*AUTOINSTPARAM*/
               // Parameters
               .width                   (8),                     // Templated
               .id                      (0+4))                   // Templated
  check0
      (/*AUTOINST*/
       // Outputs
       .c_drdy                          (out_drdy[0]),           // Templated
       // Inputs
       .clk                             (clk),
       .reset                           (reset),
       .c_srdy                          (out_srdy[0]),           // Templated
       .c_data                          (out_data[7:0]));         // Templated

  stupid_mon #(/*AUTOINSTPARAM*/
               // Parameters
               .width                   (8),                     // Templated
               .id                      (1+4))                   // Templated
    check1
      (/*AUTOINST*/
       // Outputs
       .c_drdy                          (out_drdy[1]),           // Templated
       // Inputs
       .clk                             (clk),
       .reset                           (reset),
       .c_srdy                          (out_srdy[1]),           // Templated
       .c_data                          (out_data[7:0]));         // Templated

  stupid_mon #(/*AUTOINSTPARAM*/
               // Parameters
               .width                   (8),                     // Templated
               .id                      (2+4))                   // Templated
    check2
      (/*AUTOINST*/
       // Outputs
       .c_drdy                          (out_drdy[2]),           // Templated
       // Inputs
       .clk                             (clk),
       .reset                           (reset),
       .c_srdy                          (out_srdy[2]),           // Templated
       .c_data                          (out_data[7:0]));         // Templated

  stupid_mon #(/*AUTOINSTPARAM*/
               // Parameters
               .width                   (8),                     // Templated
               .id                      (3+4))                   // Templated
    check3
      (/*AUTOINST*/
       // Outputs
       .c_drdy                          (out_drdy[3]),           // Templated
       // Inputs
       .clk                             (clk),
       .reset                           (reset),
       .c_srdy                          (out_srdy[3]),           // Templated
       .c_data                          (out_data[7:0]));         // Templated

endmodule
// Local Variables:
// verilog-library-directories:("."  "../../../rtl/verilog/forks")
// End:
