module sd_pipeline
  #(parameter width=16)
  (/*AUTOINPUT*/
  // Beginning of automatic inputs (from unused autoinst inputs)
  input [width-1:0]	c_data,			// To xin of sd_input.v
  input			c_srdy,			// To xin of sd_input.v
  input logic		clk,			// To xin of sd_input.v, ...
  input			p_drdy,			// To xout of sd_output.v
  input logic		reset,			// To xin of sd_input.v, ...
  // End of automatics
   /*AUTOOUTPUT*/
   // Beginning of automatic outputs (from unused autoinst outputs)
   output		c_drdy,			// From xin of sd_input.v
   output [width-1:0]	p_data,			// From xout of sd_output.v
   output		p_srdy			// From xout of sd_output.v
   // End of automatics
  );

  /*AUTOWIRE*/
  // Beginning of automatic wires (for undeclared instantiated-module outputs)
  logic [width-1:0]	f2o_data;		// From xfull of sd_iofull.v
  wire			f2o_drdy;		// From xout of sd_output.v
  logic			f2o_srdy;		// From xfull of sd_iofull.v
  wire [width-1:0]	i2f_data;		// From xin of sd_input.v
  logic			i2f_drdy;		// From xfull of sd_iofull.v
  wire			i2f_srdy;		// From xin of sd_input.v
  // End of automatics
   
  /* sd_input AUTO_TEMPLATE
   (
    .ip_\(.*\)  (i2f_\1[]),
   );
   */
   sd_input #(.width(width)) xin
     (/*AUTOINST*/
      // Outputs
      .c_drdy				(c_drdy),
      .ip_srdy				(i2f_srdy),		 // Templated
      .ip_data				(i2f_data[width-1:0]),	 // Templated
      // Inputs
      .clk				(clk),
      .reset				(reset),
      .c_srdy				(c_srdy),
      .c_data				(c_data[width-1:0]),
      .ip_drdy				(i2f_drdy));		 // Templated

  /* sd_iofull AUTO_TEMPLATE
   (
   .c_\(.*\)  (i2f_\1[]),
   .p_\(.*\)  (f2o_\1[]),
   );
   */
   sd_iofull #(.width(width)) xfull
     (/*AUTOINST*/
      // Outputs
      .c_drdy				(i2f_drdy),		 // Templated
      .p_srdy				(f2o_srdy),		 // Templated
      .p_data				(f2o_data[width-1:0]),	 // Templated
      // Inputs
      .clk				(clk),
      .reset				(reset),
      .c_srdy				(i2f_srdy),		 // Templated
      .c_data				(i2f_data[width-1:0]),	 // Templated
      .p_drdy				(f2o_drdy));		 // Templated

  /* sd_output AUTO_TEMPLATE
   (
    .ic_\(.*\) (f2o_\1[]),
   );
   */
   sd_output #(.width(width)) xout
     (/*AUTOINST*/
      // Outputs
      .ic_drdy				(f2o_drdy),		 // Templated
      .p_srdy				(p_srdy),
      .p_data				(p_data[width-1:0]),
      // Inputs
      .clk				(clk),
      .reset				(reset),
      .ic_srdy				(f2o_srdy),		 // Templated
      .ic_data				(f2o_data[width-1:0]),	 // Templated
      .p_drdy				(p_drdy));

endmodule
// Local Variables:
// verilog-library-directories:("." "../common" "../../../rtl/verilog/closure")
// End:
