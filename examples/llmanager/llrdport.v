/*
 * Stub simulating a read port device communicating
 * with the link list manager
 */
module llrdport
  #(parameter lpsz=8,
    parameter lpdsz=lpsz+1,
    parameter sources=4)
  (
   input clk,
   input reset,

   // page request i/f
   output reg        pgreq,
   input             pgack,

   input             lprq_srdy,
   output reg        lprq_drdy,
   input [lpsz-1:0]  lprq_page,

   // link to next page i/f
   output reg        lnp_srdy,
   input             lnp_drdy,
   output reg [lpsz+lpdsz-1:0] lnp_pnp,

   // queue to output port
   output reg        op_srdy,
   input             op_drdy,
   output reg [lpsz-1:0] op_page
   );

  reg [lpdsz-1:0]          p1, p2;
  integer                  wait_cyc;

  localparam stop_page = { 1'b1, {lpdsz-1{1'b0}} };
  

  task get_page;
    output [lpdsz-1:0] pagenum;
    begin
      @(posedge clk);
      pgreq <= 1;
      while (!pgack)
        @(posedge clk);
      pgreq <= 0;

      @(posedge clk);
      lprq_drdy <= 1;
      if (lprq_srdy)
        @(posedge clk);
      else while (!lprq_srdy)
        @(posedge clk);
      pagenum = lprq_page;
      lprq_drdy <= 0;
    end
  endtask // get_page

  task link_page;
    input [lpsz-1:0] page1;
    input [lpdsz-1:0] page2;
    begin
      @(posedge clk);
      lnp_srdy <= 1;
      lnp_pnp <= { page1, page2 };
      if (lnp_drdy)
        @(posedge clk);
      else while (!lnp_drdy)
        @(posedge clk);
      lnp_srdy <= 0;
    end
  endtask // link_page

  task send_out;
    input [lpsz-1:0] pnum;
    begin
      @(posedge clk);
      op_srdy <= 1;
      op_page <= pnum;
      if (op_drdy) @(posedge clk);
      else while (!op_drdy) @(posedge clk);
      op_srdy <= 0;
    end
  endtask

  always
    begin : aloop
      pgreq = 0;
      lprq_drdy = 0;
      lnp_srdy = 0;
      lnp_pnp  = 0;
      op_srdy = 0;
      op_page = 0;
      
      @(posedge clk);
      if (reset) disable aloop;

      // request first page and store it
      get_page (p1);
      get_page (p2);

      // link page 1 to page 2
      link_page (p1, p2);
      link_page (p2, stop_page);

      // send head page to output port
      send_out (p1);

      // wait 1-10 cycles
      wait_cyc = {$random} % 9 + 1;
      repeat (wait_cyc) @(posedge clk);
    end // block: aloop


endmodule // llrdport

