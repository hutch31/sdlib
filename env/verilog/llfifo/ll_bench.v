`timescale 1ns/1ns

module ll_bench;

  parameter width = 8;
  parameter pagesize = 16;
  parameter num_pages = 32;
  parameter num_queues = 8;
  parameter qid_sz = $clog2(num_queues);

  reg clk, reset, init;

  genvar nq;
  wire [num_queues-1:0] c_srdy_mx, c_drdy_mx;
  wire [width-1:0] 	c_data_mx[0:num_queues-1];
  wire [num_queues-1:0] p_srdy_mx, p_drdy_mx;
  reg [$clog2(num_queues)-1:0] c_qid;
  wire [width-1:0] 	       c_data;
  /*AUTOWIRE*/
  // Beginning of automatic wires (for undeclared instantiated-module outputs)
  wire			c_drdy;			// From llfifo of sd_llfifo.v
  wire [width-1:0]	p_data;			// From llfifo of sd_llfifo.v
  wire [qid_sz-1:0]	p_qid;			// From llfifo of sd_llfifo.v
  wire			p_srdy;			// From llfifo of sd_llfifo.v
  wire [num_queues-1:0]	q_empty;		// From llfifo of sd_llfifo.v
  // End of automatics
  reg [num_queues-1:0] 	rd_req;

  assign c_srdy = c_srdy_mx[c_qid];
  assign c_data = c_data_mx[c_qid];
  assign c_drdy_mx = c_drdy << c_qid;
  assign p_srdy_mx = p_srdy << p_qid;
  assign p_drdy = p_drdy_mx[p_qid];

  always
    begin
      clk = 0;
      #5;
      clk = 1;
      #5;
    end

  initial
    begin
      c_qid = 0;
      init  = 0;
      rd_req = 0;
    end

  always @(posedge clk)
    begin
      if ((c_srdy & c_drdy) || (c_srdy_mx[c_qid] == 0))
	c_qid <= c_qid + 1;
      rd_req <= {$random} & p_drdy_mx;
    end

  generate
    for (nq=0; nq<num_queues; nq=nq+1)
      begin : drv
	sd_seq_gen sg
	    (.p_srdy			(c_srdy_mx[nq]),
	     .p_data			(c_data_mx[nq]),
	     // Inputs
	     .clk			(clk),
	     .reset			(reset),
	     .p_drdy			(c_drdy_mx[nq]));
      end
  endgenerate

  sd_llfifo #(
	      // Parameters
	      .width			(width),
	      .pagesize			(pagesize),
	      .num_pages		(num_pages),
	      .num_queues		(num_queues)) llfifo
    (/*AUTOINST*/
     // Outputs
     .c_drdy				(c_drdy),
     .q_empty				(q_empty[num_queues-1:0]),
     .p_srdy				(p_srdy),
     .p_qid				(p_qid[qid_sz-1:0]),
     .p_data				(p_data[width-1:0]),
     // Inputs
     .clk				(clk),
     .reset				(reset),
     .init				(init),
     .c_srdy				(c_srdy),
     .c_qid				(c_qid[qid_sz-1:0]),
     .c_data				(c_data[width-1:0]),
     .rd_req				(rd_req[num_queues-1:0]),
     .p_drdy				(p_drdy));

  generate
    for (nq=0; nq<num_queues; nq=nq+1)
      begin : mon
	sd_seq_check sc
	    (
	     // Outputs
	     .c_drdy			(p_drdy_mx[nq]),
	     // Inputs
	     .clk			(clk),
	     .reset			(reset),
	     .c_srdy			(p_srdy_mx[nq]),
	     .c_data			(p_data));
      end
  endgenerate

  initial
    begin
      reset = 1;
      $dumpvars;
      #100;
      reset = 0;
      repeat (2)
	@(posedge clk);
      init  = 1;
      @(posedge clk);
      #5 init = 0;

      repeat (num_pages) @(posedge clk);

      drv[0].sg.send(100);
      #5000;
      $finish;
    end

endmodule // ll_bench
// Local Variables:
// verilog-library-directories:("." "../../../rtl/verilog/utility" "../common")
// End:  

