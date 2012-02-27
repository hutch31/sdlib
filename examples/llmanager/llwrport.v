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
   output reg            lprt_srdy,
   input                 lprt_drdy,
   output reg [lpsz-1:0] lprt_page_list
   );

  localparam stop_page = { 1'b1, {lpdsz-1{1'b0}} };

  wire                    p_srdy;
  wire [lpsz-1:0]         p_data;
  reg                     p_drdy;
  reg [lpdsz-1:0]         cur_page;
  integer                 wait_cyc;
  reg [lpdsz-1:0]         read_page;
  integer                 pgcount;

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
      while (!rlp_drdy)
        @(posedge clk);
      rlp_srdy <= 0;

      ack = 0;
      while (!ack)
        begin
          @(posedge clk);
          ack <= rlpr_srdy;
          rlpr_drdy <= 1;
          #1;
        end
      @(posedge clk);
/* -----\/----- EXCLUDED -----\/-----
      @(posedge clk);
      rlpr_drdy <= 1;
      if (rlpr_srdy)
        @(posedge clk);
      else while (!rlpr_srdy)
        @(posedge clk);
 -----/\----- EXCLUDED -----/\----- */
      pdata = rlpr_data;
      rlpr_drdy <= 0;
    end
  endtask // read_link_data

  task return_page;
    input [lpsz-1:0] pnum;
    begin
     @(posedge clk);
      lprt_srdy <= 1;
      lprt_page_list <= pnum;
      while (!lprt_drdy)
        @(posedge clk);
      lprt_srdy <= 0;
    end
  endtask

  always
    begin : wrportloop
      p_drdy = 0;
      rlp_srdy = 0;
      rlp_rd_page = 0;
      rlpr_drdy = 0;
      lprt_srdy = 0;
      lprt_page_list = 0;
      pgcount = 0;

      @(posedge clk);
      if (reset) disable wrportloop;

      while (!p_srdy)
        @(posedge clk);
      cur_page = p_data;
      p_drdy = 1;
      @(posedge clk);
      p_drdy = 0;

      while (cur_page != stop_page)
        begin
          read_link_data (cur_page, read_page);
          return_page (cur_page);
          cur_page = read_page;
          pgcount = pgcount + 1;
        end

      $display ("%m: LLWRPORT: Read packet with %0d pages", pgcount);

      // wait 1-10 cycles
      wait_cyc = {$random} % 9 + 1;
      repeat (wait_cyc) @(posedge clk);
    end // block: wrportloop

       
  
endmodule // llwrport

