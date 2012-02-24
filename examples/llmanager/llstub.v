module llstub
  #(parameter lpsz=8,
    parameter sinks=4,
    parameter sources=4)
  (
   input                clk,
   input                reset,

   output      [sources-1:0]  pgreq,
   input       [sources-1:0] pgack,

   // link page request return
   input [sources-1:0]      lprq_srdy,
   output reg [sources-1:0] lprq_drdy,
   input       [lpsz-1:0]   lprq_page,

   // link page reclaim interface
   output  [sinks-1:0]        lprt_srdy,
   input      [sinks-1:0]        lprt_drdy,
   output  [sinks*lpsz-1:0]   lprt_page_list
   );

  integer                        wait_time;
  reg [sources-1:0]              nreq;
  reg                            enable;

  initial
    begin
      lprq_drdy = {sinks{1'b1}};
      //lprt_srdy = {sinks{1'b0}};
      nreq = 1;
      enable = 0;

      #3000;

      enable = 1;
      #25000;
      enable = 0;

    end // initial begin

  always @(posedge clk)
    begin
      if (lprq_srdy)
        begin
          $display ("Received page number %d", lprq_page);
       end
    end

  stub_req requestors[0:sources-1]
   (.clk (clk), .reset (reset),
    .enable (enable),
    .req    (pgreq), .ack (pgack));

  wire output_srdy;
  sd_output #(.width(lpsz)) lprt_driver
    (.clk (clk), .reset (reset),
     .ic_srdy      (|lprq_srdy),
     .ic_drdy      (),
     .ic_data      (lprq_page),
     .p_srdy      (output_srdy),
     .p_drdy      (lprt_drdy[0]),
     .p_data      (lprt_page_list));

  assign lprt_srdy = output_srdy;

endmodule // llstub

module stub_req
  (
   input   clk,
   input   reset,
   input   enable,
   output reg req,
   input   ack
   );

  reg 	  load;   // true when data will be loaded into p_data
  reg 	  nxt_req;

  reg     c_srdy;
  wire    c_drdy;
  integer wait_count;

  always @(posedge clk)
    begin
      if (reset)
        begin
          wait_count = 0;
          c_srdy = 0;
        end
      else
        begin
          if (wait_count > 0)
            begin
              wait_count = wait_count - 1;
              c_srdy = 0;
            end
          else if (enable & c_drdy)
            begin
              c_srdy = 1;
              wait_count = 2;
            end
        end // else: !if(reset)
    end // else: !if(reset)

          
  always @*
    begin
      load  = c_srdy & !req;
      nxt_req = (req & !ack) | (!req & c_srdy);
    end
  assign c_drdy = ~req;
  
  always @(posedge clk)
    begin
      if (reset)
	begin
	  req <= 0;
	end
      else
	begin
	  req <= nxt_req;
	end // else: !if(reset)
    end // always @ (posedge clk)
  
endmodule // stub_req

   