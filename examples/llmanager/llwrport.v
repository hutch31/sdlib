/*
 * Stub simulating a write port device communicating
 * with the link list manager
 */
module llwrport
  #(parameter lpsz=8,
    parameter lpdsz=lpsz+1,
    parameter sinks=4)
  (
   input clk,
   input reset,

   // queue to output port
   input              op_srdy,
   output             op_drdy,
   input   [lpsz-1:0] op_page,

   // read link page i/f
   output reg         rlp_srdy,
   input              rlp_drdy,
   output reg [lpsz-1:0] rlp_rd_page,

   input              rlpr_srdy,
   output reg         rlpr_drdy,
   input [lpdsz-1:0]  rlpr_data,

   // link page reclaim interface
   output reg            drf_srdy,
   input                 drf_drdy,
   output reg [lpsz*2-1:0] drf_page_list
   );

  localparam stop_page = { 1'b1, {lpdsz-1{1'b0}} };

  wire                    p_srdy;
  wire [lpsz-1:0]         p_data;
  reg                     p_drdy;
  reg [lpdsz-1:0]         cur_page;
  integer                 wait_cyc;
  reg [lpdsz-1:0]         read_page;
  integer                 pgcount;
  integer                 packets;
  reg [lpsz-1:0]          start_page, end_page;
  event                   launch;

  sd_fifo_s #(.width(lpsz), .depth(64)) opbuf
    (
     .c_clk    (clk),
     .c_reset  (reset),
     .c_srdy   (op_srdy),
     .c_drdy   (op_drdy),
     .c_data   (op_page),

     .p_clk    (clk),
     .p_reset  (reset),
     .p_srdy   (p_srdy),
     .p_drdy   (p_drdy),
     .p_data   (p_data));

  task read_link_data;
    input [lpsz-1:0] ipage;
    output [lpdsz-1:0] pdata;
    reg                ack;
    begin
      @(posedge clk);
      rlp_srdy <= 1;
      rlp_rd_page <= ipage;
      @(posedge clk);
      while (!rlp_drdy)
        @(posedge clk);
      rlp_srdy <= 0;

      ack = 0;
      while (!ack)
        begin
          @(posedge clk);
          ack = rlpr_srdy;
          pdata = rlpr_data;
          rlpr_drdy <= 1;
        end
      @(posedge clk);
          
      //pdata = rlpr_data;
      rlpr_drdy <= 0;
    end
  endtask // read_link_data

  task return_page;
    input [lpsz-1:0] start_pnum;
    input [lpsz-1:0] end_pnum;
    begin
      @(posedge clk);
      drf_srdy <= 1;
      drf_page_list <= { start_pnum, end_pnum };
      @(posedge clk);
      while (!drf_drdy)
        @(posedge clk);
      drf_srdy <= 0;
      $display ("%t: %m: Returned page list [%0d,%0d]", $time, start_pnum, end_pnum);
      ->launch;
    end
  endtask

  initial packets = 0;

  always
    begin : wrportloop
      p_drdy = 0;
      rlp_srdy = 0;
      rlp_rd_page = 0;
      rlpr_drdy = 0;
      drf_srdy = 0;
      drf_page_list = 0;
      pgcount = 0;

      @(posedge clk);
      if (reset) disable wrportloop;

      while (!p_srdy)
        @(posedge clk);
      start_page = p_data;
      p_drdy = 1;
      @(posedge clk);
      p_drdy = 0;

      cur_page = start_page;
      while (cur_page != stop_page)
        begin
          read_link_data (cur_page, read_page);
          end_page = cur_page;
          cur_page = read_page;
          pgcount = pgcount + 1;
        end

      return_page (start_page, end_page);

      $display ("%t: %m: LLWRPORT: Read packet %0d [%0d,%0d] with %0d pages", 
                $time, packets, start_page, end_page, pgcount);
      packets = packets + 1;

      // wait 1-10 cycles
      wait_cyc = {$random} % 9 + 1;
      repeat (wait_cyc) @(posedge clk);
    end // block: wrportloop

  always @(launch)
    begin
      repeat (4) @(posedge clk);
      ->bench.free_list;
    end
  
endmodule // llwrport

