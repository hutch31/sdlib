module llstub
  #(parameter lpsz=8,
    parameter sinks=4,
    parameter sources=4)
  (
   input                clk,
   output reg [sources-1:0]  pgreq,
   input       [sources-1:0] pgack,

   // link page request return
   input [sources-1:0]      lprq_srdy,
   output reg [sources-1:0] lprq_drdy,
   input       [lpsz-1:0]   lprq_page,

   // link page reclaim interface
   output reg [sinks-1:0]        lprt_srdy,
   input      [sinks-1:0]        lprt_drdy,
   output reg [sinks*lpsz-1:0]   lprt_page_list
   );

  integer                        wait_time;
  reg [sources-1:0]              nreq;

  initial
    begin
      lprq_drdy = {lpsz{1'b1}};
      lprt_srdy = {sinks{1'b0}};
      pgreq = 0;
      nreq = 1;

      #500;

      repeat (100)
        begin
          wait_time = ({$random} % 50) + 10;
          $display ("Waiting %d", wait_time);
          @(posedge clk);
          pgreq <= { nreq[sources-2:0], nreq[sources-1] };
          @(posedge clk);
          pgreq <= 0;

          repeat (wait_time)
            @(posedge clk);
        end
    end


endmodule // llstub

   