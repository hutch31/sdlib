module harness_control
  #(parameter ports=8)
  (output reg clk,
   output reg rst,
   output [ports-1:0] active,
   input [ports-1:0] targ_error,
   input [ports-1:0] seq_error
   );

  reg 		     failed;
  
  always
    begin
      clk = 0;
      #5;
      clk = 1;
      #5;
    end

  assign active = {ports{1'b1}};

  initial
    begin
      $vcdpluson;
      failed = 0;
      rst = 1;
      #100;
      rst = 0;

      repeat (500)
	begin
	  @(posedge clk);
	  if ((targ_error !== {ports{1'b0}}) || (seq_error !== {ports{1'b0}}))
	    failed = 1;
	end

      if (failed)
	$display ("!!! TEST FAILED !!!");
      else
	$display ("--- TEST PASSED ---");
      $finish;
    end

endmodule
