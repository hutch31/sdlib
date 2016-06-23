//-------------------------------------------
// FIFO Module: Auto generated do not modify
//  TYPE:  sr
//  DEPTH: 64
//  WIDTH: 246
//  NOECC: 0
//-------------------------------------------


module xp_fifo_sr64x246_s (
   input [245:0]        c_data,
   input                   c_srdy,
   input [5:0]       cfg_addr,
   input                   cfg_rd_req,
   input [245:0]        cfg_wr_data,
   input                   cfg_wr_req,

   // diag hooks
   input logic             enqEn,
   input logic             deqEn,
   input logic             contEnq,
   input logic             contDeq,
   input logic             fifo_ptr_rd_req,
   output logic            fifo_ptr_rd_ack,
   output logic [13:0] fifo_ptr_rd_data,
   input logic             fifo_ptr_wr_req,
   output logic            fifo_ptr_wr_ack,
   input logic [13:0]  fifo_ptr_wr_data,

   input                   clk,
   input                   rst,
   input                   p_drdy,

    input [2-1:0] 	bist_run,
    input 		bist_rpr_mode,
    input 		bist_ptrn_fill,
    input       bist_mem_rst,
    output [2-1:0] bist_done_pass_out,
    output [2-1:0] bist_done_fail_out,
   
   input  logic            flip_db_ecc,
   input  logic            flip_sb_ecc,
   output logic            c_drdy,
   output logic [6:0] c_usage,
   output logic            cfg_rd_ack,
   output logic [245:0] cfg_rd_data,
   output logic            cfg_wr_ack,
   output logic            db_err,
   output logic [245:0] p_data,
   output logic            p_srdy,
   output logic [6:0] p_usage,
   output logic            sb_err
   );

   localparam RDTAP = 2;

   logic                   mem_ld, pf_uld;

   logic                   mem_empty, mem_full;
   logic [245:0]        func_d_out;
   logic [5:0]       func_wr_addr;
   logic [5:0]       func_rd_addr;
   logic [6:0]        mem_cnt;            // count from 0 - DEPTH + 3
   logic                   func_rd_en;
   logic                   mem_rd;             // issue a read to the mem
   logic                   pf_eld;             // early pre-fetch load
   logic                   pf_ld;              // pre-fetch load
   logic                   ic_drdy;
   logic [2:0]             rdT;
   logic                   use_pf;
   logic [4:0][245:0]   pipeT;
   logic [2:0]             wrPtr, rdPtr, rdPtr_buffer;
   logic [2:0]             pfCnt;
   logic                   pfFull;
   logic [2:0]             realCnt;
   logic                   c_ld, p_uld;

   assign fifo_ptr_rd_ack = 1'b1;
   assign fifo_ptr_rd_data = {func_rd_addr, func_wr_addr, mem_full, mem_empty};
   assign c_drdy = contEnq ? 1'b1 : enqEn ? !mem_full : 1'b0;

   assign p_usage = mem_cnt + pfCnt;
   assign c_usage = mem_cnt + pfCnt;

   // these signals represent push & pop at the overall fifo interface
   assign c_ld   = c_srdy & c_drdy;
   assign p_uld  = p_srdy & p_drdy;

   assign mem_ld = c_srdy & c_drdy & !use_pf; 
   assign pf_uld = p_drdy & p_srdy;
   wire test_pf1, test_pf2, test_pf3;
   assign test_pf3 = (!pfFull || (pfFull&pf_uld));
   assign test_pf1 = !func_rd_en;
   assign test_pf2 = ~|rdT[RDTAP:0];
   assign use_pf = (mem_empty & !func_rd_en & ~|rdT[RDTAP:0] & (!pfFull || (pfFull&pf_uld)) );

	   // need to read the memory when the sd_outputs can absorb a read
	   // alse need to account for the memory read latency
	   assign  mem_rd = !mem_empty & (pf_uld | !pfFull);
	   assign  pf_eld  = !mem_empty ? (pf_uld | !pfFull) : c_srdy & use_pf;
	   assign  pf_ld   = rdT[RDTAP] || use_pf && c_srdy;
	  

	   always @ (posedge clk) begin
	     func_rd_en <= mem_rd;

	     if ( rst ) begin
	       func_wr_addr <= 6'h0;
	       func_rd_addr <= 6'h0;
	       mem_empty    <= 1'b1;
	       mem_full     <= 1'b0;
	       mem_cnt      <= 7'h0;
	       fifo_ptr_wr_ack <= 1'b0;
	       rdT 	    <= 3'b0;
	       
	     end
	     else begin
	       if ( mem_ld ) begin
		 func_wr_addr <= (func_wr_addr == 63) ? 6'h0 : func_wr_addr + 1;
	       end

	       if ( func_rd_en ) begin
		 func_rd_addr <= (func_rd_addr == 63) ? 6'h0 : func_rd_addr + 1;
	       end

	       if ( mem_ld & !mem_rd ) begin
		 mem_empty <= 1'b0;
		 mem_cnt <= mem_cnt + 1;
		 if ( mem_cnt == 63 )
		   mem_full <= 1'b1;
	       end
	       else if ( !mem_ld & mem_rd ) begin
		 mem_full <= 1'b0;
		 mem_cnt <= mem_cnt - 1;
		 if ( mem_cnt == 1 )
		   mem_empty <= 1'b1;
	       end

	       if ( ~|{mem_ld, mem_rd, func_rd_en} && fifo_ptr_wr_req & !fifo_ptr_wr_ack ) begin
		 {func_rd_addr, func_wr_addr, mem_full, mem_empty} <= fifo_ptr_wr_data;
		 fifo_ptr_wr_ack <= 1'b1;
	       end
	       else begin
		 fifo_ptr_wr_ack <= 1'b0;
	       end
	     end

	     rdT[2:0] <= {rdT[1:0],func_rd_en};
	   end

	   xp_mem_wrap_sr64x246 mem2p (
	      // Outputs
	      .cfg_rd_data         (cfg_rd_data),
	      .cfg_rd_ack          (cfg_rd_ack),
	      .cfg_wr_ack          (cfg_wr_ack),
	      .func_wr_ack         (),        
	      .func_rd_ack         (),
	      .func_d_out          (func_d_out),
	      .sb_err              (sb_err),
	      .db_err              (db_err),

	      .bist_run (bist_run),
	      .bist_rpr_mode (bist_rpr_mode),
	      .bist_ptrn_fill (bist_ptrn_fill),
	      .bist_done_pass_out (bist_done_pass_out),
	      .bist_done_fail_out (bist_done_fail_out),
	      .bist_mem_rst       (bist_mem_rst),

	      // Inputs
	      .wr_clk              (clk),        
	      .rd_clk              (clk),
	      .rd_reset            (rst),
	      .flip_sb_ecc         (flip_sb_ecc),
	      .flip_db_ecc         (flip_db_ecc),
	      .cfg_wr_req          (cfg_wr_req),
	      .cfg_rd_req          (cfg_rd_req),
	      .cfg_wr_data         (cfg_wr_data),
	      .cfg_addr            (cfg_addr),
	      .func_wr_en          (mem_ld),
	      .func_rd_en          (func_rd_en),
	      .func_d_in           (c_data), 
	         .func_rd_addr        (func_rd_addr),
	      .func_wr_addr        (func_wr_addr));

	   // Prefetch logic, this reads from the memory and holds upto three entries
	   always @ (posedge clk) begin
	     if ( rst ) begin
	       wrPtr <= 3'h0;
	       rdPtr <= 3'h0;
	       pfCnt <= 3'h0;   // early version of cnt, increments when mem rd is issued
       pfFull <= 1'b0;
       realCnt <= 3'h0;
       pipeT[0] <= 246'b0;
pipeT[1] <= 246'b0;
pipeT[2] <= 246'b0;
pipeT[3] <= 246'b0;
pipeT[4] <= 246'b0; 
     end
     else begin
	rdPtr_buffer <= rdPtr;
       if ( pf_uld )
         rdPtr <= (rdPtr == 4) ? 3'h0 : rdPtr + 1;

       if ( pf_ld )
         wrPtr <= (wrPtr == 4) ? 3'h0 : wrPtr + 1;

       // track entries in pre-fetch stages
       if ( pf_eld  & !pf_uld ) begin
			 pfCnt <= pfCnt + 1;
         pfFull <= (pfCnt == 4); 
       end
       else if ( !pf_eld  & pf_uld ) begin
         pfCnt <= pfCnt - 1;
         pfFull <= 1'b0;
       end

       if ( pf_ld & !pf_uld )
         realCnt <= realCnt + 1;
       else if ( !pf_ld & pf_uld )
         realCnt <= realCnt - 1;
     end

     if ( pf_ld ) 
       pipeT[wrPtr] <= rdT[RDTAP] ? func_d_out : c_data; // ri lint_check_waive

   end

   assign p_data = pipeT[rdPtr];
   assign p_srdy = contDeq ? 1'b1 : deqEn ? (realCnt == 5) || (wrPtr != rdPtr) : 1'b0;


   // synopsys translate_off
// initial begin
//   force enqEn = 1'b1;
//   force deqEn = 1'b1;
//   force contEnq = 1'b0;
//   force contDeq = 1'b0;
//   force fifo_ptr_wr_req = 1'b0;
// end

   int pucnt, pocnt;
   always @ (posedge clk) begin
     if ( !rst ) begin
       if ( c_srdy & c_drdy ) begin
         //$display ("@%0t %m: PUSH# %0d: %0h", $time, pucnt, c_data);
         pucnt++;
       end

       if ( pf_uld ) begin
         //$display ("@%0t %m: POP#  %0d: %0h", $time, pocnt, p_data);
         pocnt++;
       end
     end
   end

   final begin
     if ( pucnt > 0 ) begin
       $display ("@%0t %m: TOTAL ENTRIES PUSHED: %0d, POPPED: %0d", $time, pucnt, pocnt);
     end
   end
   // synopsys translate_on
endmodule
// Local Variables:
// verilog-library-directories:("." "$XP_ROOT/rtl/common" "$XP_ROOT/rtl/common/memory" "$XP_ROOT/lib/sdlib/rtl/verilog/*")
// verilog-auto-inst-param-value: t
// End:
