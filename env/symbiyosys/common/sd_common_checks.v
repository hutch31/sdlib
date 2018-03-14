module sd_common_checks
 #(parameter width = 16)
 (
  input clk,
  input reset,

  input [width-1:0]   c_data,
  input               c_srdy,
  input               c_drdy,
  input  [width-1:0]  p_data,
  input               p_srdy,
  input               p_drdy,
  output integer      in_count,
  output integer      out_count
 );

  always @(posedge clk)
    begin
      if (reset)
        begin
          in_count <= 0;
          out_count <= 0;
        end
      else
        begin
          // input data is held until drdy
          if (c_srdy & !c_drdy)
            assume($stable(c_data));

          // output data held until acknowledged
          if (p_srdy & !p_drdy)
            assert($stable(p_data));

          // count input words as they arrive
          if (c_srdy & c_drdy)
            in_count <= in_count + 1;

          if (p_srdy & p_drdy)
            out_count <= out_count + 1;

          // will not flow control indefinately
          assume (s_eventually !p_drdy);

          // data pushed in will eventually go out
          if (c_srdy & !p_drdy)
            assert (s_eventually p_srdy);

          // if FIFO is empty input tokens should equal output tokens
          if (!p_srdy)
            assert (in_count == out_count);
        end
    end

endmodule

