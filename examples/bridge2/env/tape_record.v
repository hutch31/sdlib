module tape_record
  #(parameter width=32)
  (
   input              clk,
   input [width-1:0]  data
   );

  integer             fh;

  initial
    begin
      fh = $fopen ("tape_record.vmem","w");
    end

  always @(posedge clk)
    begin
      $fwrite (fh, "%b\n", data);
    end

endmodule // tape_record
