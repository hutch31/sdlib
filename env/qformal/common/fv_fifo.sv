module fv_fifo
  #(parameter width = 8,
    parameter depth = 8)
  (
   input clk,
   input reset,

   input push,
   input [width-1:0] push_data,

   input pop,
   output [width-1:0] pop_data,
   output pop_valid
   );

  localparam fptr_sz = $clog2(depth);
  logic [depth-1:0][width-1:0] fdata;
  logic [fptr_sz-1:0]          head, tail;

  always @(posedge clk)
    begin
      if (reset)
        begin
          head <= 0;
          tail <= 0;
        end
      else
        begin
          if (push)
            begin
              if (head == (depth-1))
                head <= 0;
              else
                head <= head + 1;
            end
          if (pop)
            begin
              if (tail == (depth-1))
                tail <= 0;
              else
                tail <= tail + 1;
            end
        end // else: !if(reset)
    end // always @ (posedge clk)

  always @(posedge clk)
    begin
      if (push)
        fdata[head] <= push_data;
    end

  assign pop_data = fdata[tail];
  assign pop_valid = (head != tail);
      
endmodule // sv_fifo

   
