module ftest_gearbox
 #(parameter inw = 64,
   parameter inm = 5,
   parameter outw = 40,
   parameter outm = 8)
 (
  input clk,
  input reset,

  //input [63:0]  c_data,
  input         c_srdy,
  output reg    c_drdy,
  output [31:0] p_data,
  output reg    p_srdy,
  input         p_drdy
 );

  reg [inw*inm-1:0]   full_in_vec = $anyconst;
  reg [outw*outm-1:0] full_out_vec;
  reg [$clog2(inm)-1:0] in_count = 0;
  reg [$clog2(outm)-1:0] out_count = 0;
  wire [inw-1:0] c_data = full_in_vec >> (inw * in_count);

  // basic parameter check to see if multiples correctly assigned
  initial
    assert ((inw * inm) == (outw * outm));

  initial
    begin
      assume(reset);
    end

  sd_gearbox #(.inw(inw), .outw(outw)) gb
    (.clk (clk),
     .reset (reset),
     .c_data (c_data),
     .c_srdy (c_srdy),
     .c_drdy (c_drdy),
     .p_srdy (p_srdy),
     .p_drdy (p_drdy),
     .p_data (p_data)
    );

  always @(posedge clk)
    begin
      if (reset)
        begin
          full_out_vld <= 0;
          in_count <= 0;
          out_count <= 0;
        end
      else
        begin
          assume(in_count <= inm); 
          assume(out_count <= outm); 

          if (c_srdy)
            assume($stable(c_data));

          // count input words as they arrive
          if (c_srdy & c_drdy)
            in_count <= in_count + 1;

          // count output words as they arrive and shift into output vector
          if (p_srdy & p_drdy)
            begin
              full_out_vec <= full_out_vec | (p_data << (out_count*outw));
              out_count <= out_count + 1;
            end

          // output vector should eventually match input vector
          if (out_count == outm)
            assert (full_out_vec == full_in_vec);

          // will not flow control indefinately
          assume (s_eventually !p_drdy);

          // data pushed in will eventually go out
          if (c_srdy & !p_drdy)
            assert (s_eventually p_srdy);
        end
    end

endmodule

