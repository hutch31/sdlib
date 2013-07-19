//----------------------------------------------------------------------
//  Linked List FIFO
//
// Maintains multiple FIFOs in a single memory.  All FIFOs dynamically
// allocate storage from a central pool.
//
// Naming convention: c = consumer, p = producer, i = internal interface
//----------------------------------------------------------------------
//  Author: Guy Hutchison
//
// This block is uncopyrighted and released into the public domain.
//----------------------------------------------------------------------
// This is free and unencumbered software released into the public domain.
//
// Anyone is free to copy, modify, publish, use, compile, sell, or
// distribute this software, either in source code form or as a compiled
// binary, for any purpose, commercial or non-commercial, and by any
// means.
//
// In jurisdictions that recognize copyright laws, the author or authors
// of this software dedicate any and all copyright interest in the
// software to the public domain. We make this dedication for the benefit
// of the public at large and to the detriment of our heirs and
// successors. We intend this dedication to be an overt act of
// relinquishment in perpetuity of all present and future rights to this
// software under copyright law.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
// IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
// OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
// ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
// OTHER DEALINGS IN THE SOFTWARE.
//
// For more information, please refer to <http://unlicense.org/> 
//----------------------------------------------------------------------

module sd_llfifo
  #(parameter width=8,
    parameter pagesize=16,
    parameter num_pages=32,
    parameter num_queues=8,
    parameter qid_sz=$clog2(num_queues))

  (input      clk,
   input      reset,
   input      init,

   input      c_srdy,
   output     c_drdy,
   input [qid_sz-1:0] c_qid,
   input [width-1:0] c_data,

   input [num_queues-1:0] rd_req,
   output [num_queues-1:0] q_empty,

   output     p_srdy,
   input      p_drdy,
   output [qid_sz-1:0]  p_qid,
   output [width-1:0]   p_data
   );

  localparam depth = num_pages*pagesize;
  localparam mm_sz=$clog2(num_pages*pagesize);
  localparam pid_sz=$clog2(num_pages);

  wire [width-1:0] 	mm_d_out;
  wire [pid_sz-1:0] 	flr_data;		// From free_list of sd_fifo_s.v
  wire [pid_sz-1:0] 	lm_d_out;		// From link_list of behave2p_mem.v
  /*AUTOWIRE*/
  // Beginning of automatic wires (for undeclared instantiated-module outputs)
  wire [pid_sz-1:0]	lm_d_in;		// From llfifo_ctl of sd_llfifo_ctl.v
  wire [pid_sz-1:0]	lm_rd_addr;		// From llfifo_ctl of sd_llfifo_ctl.v
  wire			lm_rd_en;		// From llfifo_ctl of sd_llfifo_ctl.v
  wire [pid_sz-1:0]	lm_wr_addr;		// From llfifo_ctl of sd_llfifo_ctl.v
  wire			lm_wr_en;		// From llfifo_ctl of sd_llfifo_ctl.v
  wire [mm_sz-1:0]	mm_addr;		// From llfifo_ctl of sd_llfifo_ctl.v
  wire			mm_rd_en;		// From llfifo_ctl of sd_llfifo_ctl.v
  wire			mm_wr_en;		// From llfifo_ctl of sd_llfifo_ctl.v
  wire [qid_sz-1:0]	pv_qid;			// From llfifo_ctl of sd_llfifo_ctl.v
  wire			pv_rd;			// From llfifo_ctl of sd_llfifo_ctl.v
  // End of automatics

  behave1p_mem #(.depth			(depth),
		 .width			(width)) mainmem
    (// Outputs
     .d_out				(mm_d_out[width-1:0]),
     // Inputs
     .wr_en				(mm_wr_en),
     .rd_en				(mm_rd_en),
     .clk				(clk),
     .d_in				(c_data),
     .addr				(mm_addr));

/* sd_fifo_s AUTO_TEMPLATE
 (
     .[pc]_clk				(clk),
     .[pc]_reset			(reset),
 .c_\(.*\)   (flw_\1),
 .p_\(.*\)   (flr_\1),
 );
 */
/* -----\/----- EXCLUDED -----\/-----
 sd_fifo_s #(.width			(pid_sz),
	     .depth			(num_pages)) free_list
    (/-*AUTOINST*-/
     // Outputs
     .c_drdy				(flw_drdy),
     .p_srdy				(flr_srdy),
     .p_data				(flr_data),
     // Inputs
     .c_clk				(clk),
     .c_reset				(reset),
     .c_srdy				(flw_srdy),
     .c_data				(flw_data),
     .p_clk				(clk),
     .p_reset				(reset),
     .p_drdy				(flr_drdy));
 -----/\----- EXCLUDED -----/\----- */

/* behave2p_mem AUTO_TEMPLATE
 (
     .wr_clk				(clk),
     .rd_clk				(clk),
     .\(.*\)          (lm_\1),
 );
 */
  behave2p_mem #(.width			($clog2(num_pages)),
		 .depth			($clog2(num_pages)),
		 .addr_sz		(pid_sz)) link_list
    (/*AUTOINST*/
     // Outputs
     .d_out				(lm_d_out),		 // Templated
     // Inputs
     .wr_en				(lm_wr_en),		 // Templated
     .rd_en				(lm_rd_en),		 // Templated
     .wr_clk				(clk),			 // Templated
     .rd_clk				(clk),			 // Templated
     .d_in				(lm_d_in),		 // Templated
     .rd_addr				(lm_rd_addr),		 // Templated
     .wr_addr				(lm_wr_addr));		 // Templated

  sd_llfifo_ctl #(.width		(width),
		  .pagesize		(pagesize),
		  .num_pages		(num_pages),
		  .num_queues		(num_queues)) llfifo_ctl
    (
     /*AUTOINST*/
     // Outputs
     .c_drdy				(c_drdy),
     .mm_wr_en				(mm_wr_en),
     .mm_rd_en				(mm_rd_en),
     .mm_addr				(mm_addr[mm_sz-1:0]),
     .pv_rd				(pv_rd),
     .pv_qid				(pv_qid[qid_sz-1:0]),
     .lm_wr_en				(lm_wr_en),
     .lm_rd_en				(lm_rd_en),
     .lm_d_in				(lm_d_in[pid_sz-1:0]),
     .lm_rd_addr			(lm_rd_addr[pid_sz-1:0]),
     .lm_wr_addr			(lm_wr_addr[pid_sz-1:0]),
     // Inputs
     .clk				(clk),
     .reset				(reset),
     .init				(init),
     .c_srdy				(c_srdy),
     .c_qid				(c_qid[qid_sz-1:0]),
     .mm_d_out				(mm_d_out[width-1:0]),
     .rd_req				(rd_req[num_queues-1:0]),
     .lm_d_out				(lm_d_out[pid_sz-1:0]));

  sd_iohalf #(qid_sz+width) out_hold
    (.c_srdy (pv_rd), .c_drdy (),
     .c_data ({pv_qid,mm_d_out}),

     .p_srdy (p_srdy),
     .p_drdy (p_drdy),
     .p_data ({p_qid, p_data}),
     /*AUTOINST*/
     // Inputs
     .clk				(clk),
     .reset				(reset));
	  
endmodule // sd_llfifo
// Local Variables:
// verilog-library-directories:("." "../buffers" "../closure" "../memory")
// End:  
