module ftest_gearbox
 #(parameter width = 16,
   parameter depth = 8,
   parameter usz=$clog2(depth+1))
 (
  input clk,

  input [width-1:0]   c_data,
  input               c_srdy,
  output              c_drdy,
  output [width-1:0]  p_data,
  output              p_srdy,
  input               p_drdy,
  output  [usz-1:0]   usage
 );

  logic reset = 1;
  wire [31:0] in_count, out_count;

  initial
    begin
      assume(reset);
    end

  sd_fifo_c #(.width(width), .depth(depth)) fifo_c
    (.clk    (clk), 
     .reset  (reset),
     .c_srdy (c_srdy),
     .c_drdy (c_drdy),
     .c_data (c_data),
     .usage  (usage),
     .p_srdy (p_srdy),
     .p_drdy (p_drdy),
     .p_data (p_data));

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

  always @(posedge clk)
    begin
      if (~reset)
        assert((in_count - out_count) == usage);
    end
/*
  always @(posedge clk)
    begin
      if (reset)
        begin
          in_count <= 0;
          out_count <= 0;
        end
      else
        begin
          if (gb_in_srdy)
            assume($stable(gb_in_data));

          // count input words as they arrive
          if (c_srdy & c_drdy)
            in_count <= in_count + 1;

          if (p_srdy & p_drdy)
            out_count <= out_count + 1;

          assert((in_count - out_count) == usage);

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
*/
endmodule

