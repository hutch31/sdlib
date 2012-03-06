/*
 * Stub simulating a read port device communicating
 * with the link list manager
 */
`define PCOUNT 10

module llrdport
  #(parameter lpsz=8,
    parameter lpdsz=lpsz+1,
    parameter sources=4)
  (
   input clk,
   input reset,

   // page request i/f
   output reg        par_srdy,
   input             par_drdy,

   input             parr_srdy,
   output reg        parr_drdy,
   input [lpsz-1:0]  parr_page,

   // link to next page i/f
   output reg        lnp_srdy,
   input             lnp_drdy,
   output reg [lpsz+lpdsz-1:0] lnp_pnp,

   // queue to output port
   output reg        ip_srdy,
   input             ip_drdy,
   output reg [lpsz-1:0] ip_page
   );

  reg [lpdsz-1:0]          p1, p2, p3;
  integer                  wait_cyc;

  localparam stop_page = { 1'b1, {lpdsz-1{1'b0}} };

  wire [lpdsz-1:0]         stop;
  integer                  packets;

  assign stop = stop_page;

  task get_page;
    output [lpdsz-1:0] pagenum;
    reg                ack;
    begin
      ack = 0;
      @(posedge clk);
      par_srdy <= 1;
      @(posedge clk);
      while (!par_drdy)
        @(posedge clk);
      par_srdy <= 0;

      ack = 0;
      while (!ack)
        begin
          @(posedge clk);
          ack <= parr_srdy;
          parr_drdy <= 1;
          #1;
        end
      @(posedge clk);

      pagenum = parr_page;
      parr_drdy <= 0;
      $display ("%t: %m: Received page %0d", $time, pagenum);
      bench.print_free_list;
    end
  endtask // get_page

  task link_page;
    input [lpsz-1:0] page1;
    input [lpdsz-1:0] page2;
    reg               ack;
    begin
      @(posedge clk);
      lnp_srdy <= 1;
      lnp_pnp <= { page1, page2 };
      @(posedge clk);
      while (!lnp_drdy)
        @(posedge clk);
      lnp_srdy <= 0;
    end
  endtask // link_page

  task send_out;
    input [lpsz-1:0] pnum;
    begin
      @(posedge clk);
      ip_srdy <= 1;
      ip_page <= pnum;
      //if (ip_drdy) @(posedge clk);
      @(posedge clk);
      while (!ip_drdy) @(posedge clk);
      ip_srdy <= 0;
    end
  endtask

  initial packets = 0;

  always
    begin : aloop
      par_srdy = 0;
      parr_drdy = 0;
      lnp_srdy = 0;
      lnp_pnp  = 0;
      ip_srdy = 0;
      ip_page = 0;
      
      @(posedge clk);
      if (reset || (packets > `PCOUNT)) disable aloop;
      $display ("%t: %m: Sourcing packet %0d", $time, packets);

      // request first page and store it
      get_page (p1);
      get_page (p2);

      // link page 1 to page 2
      link_page (p1, p2);

      // get third page, link 2 to 3 and stop
      get_page (p3);
      link_page (p2, p3);
      link_page (p3, stop_page);

      // send head page to output port
      send_out (p1);

      // wait 1-10 cycles
      wait_cyc = {$random} % 9 + 1;
      repeat (wait_cyc) @(posedge clk);

      packets = packets + 1;
    end // block: aloop


endmodule // llrdport

