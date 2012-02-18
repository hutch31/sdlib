module port_macro
  #(parameter port_num = 0)
  (input         clk,
   input         reset,

   input [`PRW_SZ-1:0]	ri_data,		// To ring_tap of port_ring_tap.v
   output [`PRW_SZ-1:0]	ro_data,		// From ring_tap of port_ring_tap.v
   input [`NUM_PORTS-1:0] fli_data,		// To ring_tap of port_ring_tap.v
   /*AUTOINPUT*/
   // Beginning of automatic inputs (from unused autoinst inputs)
   input		fli_srdy,		// To ring_tap of port_ring_tap.v
   input		gmii_rx_clk,		// To port_clocking of port_clocking.v, ...
   input		gmii_rx_dv,		// To rx_gigmac of sd_rx_gigmac.v
   input [7:0]		gmii_rxd,		// To rx_gigmac of sd_rx_gigmac.v
   input		p2f_drdy,		// To pkt_parse of pkt_parse.v
   input		rarb_ack,		// To ring_tap of port_ring_tap.v
   input		ri_srdy,		// To ring_tap of port_ring_tap.v
   input		ro_drdy,		// To ring_tap of port_ring_tap.v
   // End of automatics

   output               rarb_req,
   output		fli_drdy,		// From ring_tap of port_ring_tap.v
   output		gmii_tx_en,		// From tx_gmii of sd_tx_gigmac.v
   output [7:0]		gmii_txd,		// From tx_gmii of sd_tx_gigmac.v
   output [`PAR_DATA_SZ-1:0] p2f_data,		// From pkt_parse of pkt_parse.v
   output		p2f_srdy,		// From pkt_parse of pkt_parse.v
   output		ri_drdy,		// From ring_tap of port_ring_tap.v
   output		ro_srdy 		// From ring_tap of port_ring_tap.v
   );

  wire [`RX_USG_SZ-1:0] rx_usage;
  wire [`TX_USG_SZ-1:0] tx_usage;
  wire [`PFW_SZ-1:0]	prx_data;		// From fifo_rx of sd_fifo_b.v
  wire [`PFW_SZ-1:0]	ptx_data;		// From fifo_tx of sd_fifo_b.v
  wire [`PFW_SZ-1:0]	rttx_data;		// From ring_tap of port_ring_tap.v
  wire [1:0] 		rxg_code;		// From rx_sync_fifo of sd_fifo_s.v
  wire [7:0] 		rxg_data;		// From rx_sync_fifo of sd_fifo_s.v
  wire [`PFW_SZ-1:0]	ctx_data;		// From oflow of egr_oflow.v
  /*AUTOWIRE*/
  // Beginning of automatic wires (for undeclared instantiated-module outputs)
  wire			crx_abort;		// From con of concentrator.v
  wire			crx_commit;		// From con of concentrator.v
  wire [`PFW_SZ-1:0]	crx_data;		// From con of concentrator.v
  wire			crx_drdy;		// From fifo_rx of sd_fifo_b.v
  wire			crx_srdy;		// From con of concentrator.v
  wire			ctx_abort;		// From oflow of egr_oflow.v
  wire			ctx_commit;		// From oflow of egr_oflow.v
  wire			ctx_drdy;		// From fifo_tx of sd_fifo_b.v
  wire			ctx_srdy;		// From oflow of egr_oflow.v
  wire			gmii_rx_reset;		// From port_clocking of port_clocking.v
  wire [1:0]		pdo_code;		// From pkt_parse of pkt_parse.v
  wire [7:0]		pdo_data;		// From pkt_parse of pkt_parse.v
  wire			pdo_drdy;		// From con of concentrator.v
  wire			pdo_srdy;		// From pkt_parse of pkt_parse.v
  wire			prx_drdy;		// From ring_tap of port_ring_tap.v
  wire			prx_srdy;		// From fifo_rx of sd_fifo_b.v
  wire			ptx_drdy;		// From dst of distributor.v
  wire			ptx_srdy;		// From fifo_tx of sd_fifo_b.v
  wire			rttx_drdy;		// From oflow of egr_oflow.v
  wire			rttx_srdy;		// From ring_tap of port_ring_tap.v
  wire [1:0]		rxc_rxg_code;		// From rx_gigmac of sd_rx_gigmac.v
  wire [7:0]		rxc_rxg_data;		// From rx_gigmac of sd_rx_gigmac.v
  wire			rxc_rxg_drdy;		// From rx_sync_fifo of sd_fifo_s.v
  wire			rxc_rxg_srdy;		// From rx_gigmac of sd_rx_gigmac.v
  wire			rxg_drdy;		// From pkt_parse of pkt_parse.v
  wire			rxg_srdy;		// From rx_sync_fifo of sd_fifo_s.v
  wire [1:0]		txg_code;		// From dst of distributor.v
  wire [7:0]		txg_data;		// From dst of distributor.v
  wire			txg_drdy;		// From tx_gmii of sd_tx_gigmac.v
  wire			txg_srdy;		// From dst of distributor.v
  // End of automatics


  port_clocking port_clocking
    (/*AUTOINST*/
     // Outputs
     .gmii_rx_reset			(gmii_rx_reset),
     // Inputs
     .clk				(clk),
     .reset				(reset),
     .gmii_rx_clk			(gmii_rx_clk));

/*  sd_rx_gigmac AUTO_TEMPLATE
 (
   .clk				(gmii_rx_clk),
   .reset			(gmii_rx_reset),
   .rxg_\(.*\)			(rxc_rxg_\1[]),
 );
 */
  sd_rx_gigmac rx_gigmac
    (/*AUTOINST*/
     // Outputs
     .rxg_srdy				(rxc_rxg_srdy),		 // Templated
     .rxg_code				(rxc_rxg_code[1:0]),	 // Templated
     .rxg_data				(rxc_rxg_data[7:0]),	 // Templated
     // Inputs
     .clk				(gmii_rx_clk),		 // Templated
     .reset				(gmii_rx_reset),	 // Templated
     .gmii_rx_dv			(gmii_rx_dv),
     .gmii_rxd				(gmii_rxd[7:0]),
     .rxg_drdy				(rxc_rxg_drdy));		 // Templated

/* sd_fifo_s AUTO_TEMPLATE
 (
     .c_clk				(gmii_rx_clk),
     .c_reset				(gmii_rx_reset),
     .c_data				({rxc_rxg_code,rxc_rxg_data}),
     .p_data				({rxg_code,rxg_data}),
     .p_clk				(clk),
     .p_reset				(reset),
  .c_\(.*\)			(rxc_rxg_\1[]),
  .p_\(.*\)			(rxg_\1[]),
 );
 */
  sd_fifo_s #(8+2,16,1) rx_sync_fifo
    (/*AUTOINST*/
     // Outputs
     .c_drdy				(rxc_rxg_drdy),		 // Templated
     .p_srdy				(rxg_srdy),		 // Templated
     .p_data				({rxg_code,rxg_data}),	 // Templated
     // Inputs
     .c_clk				(gmii_rx_clk),		 // Templated
     .c_reset				(gmii_rx_reset),	 // Templated
     .c_srdy				(rxc_rxg_srdy),		 // Templated
     .c_data				({rxc_rxg_code,rxc_rxg_data}), // Templated
     .p_clk				(clk),			 // Templated
     .p_reset				(reset),		 // Templated
     .p_drdy				(rxg_drdy));		 // Templated

  pkt_parse #(port_num) pkt_parse
    (/*AUTOINST*/
     // Outputs
     .rxg_drdy				(rxg_drdy),
     .p2f_srdy				(p2f_srdy),
     .p2f_data				(p2f_data[`PAR_DATA_SZ-1:0]),
     .pdo_srdy				(pdo_srdy),
     .pdo_code				(pdo_code[1:0]),
     .pdo_data				(pdo_data[7:0]),
     // Inputs
     .clk				(clk),
     .reset				(reset),
     .rxg_srdy				(rxg_srdy),
     .rxg_code				(rxg_code[1:0]),
     .rxg_data				(rxg_data[7:0]),
     .p2f_drdy				(p2f_drdy),
     .pdo_drdy				(pdo_drdy));

/* concentrator AUTO_TEMPLATE
 (
    .c_\(.*\)     (pdo_\1[]),
    .p_\(.*\)     (crx_\1[]),
 );
 */
  concentrator con
    (/*AUTOINST*/
     // Outputs
     .c_drdy				(pdo_drdy),		 // Templated
     .p_data				(crx_data[`PFW_SZ-1:0]), // Templated
     .p_srdy				(crx_srdy),		 // Templated
     .p_commit				(crx_commit),		 // Templated
     .p_abort				(crx_abort),		 // Templated
     // Inputs
     .clk				(clk),
     .reset				(reset),
     .c_data				(pdo_data[7:0]),	 // Templated
     .c_code				(pdo_code[1:0]),	 // Templated
     .c_srdy				(pdo_srdy),		 // Templated
     .p_drdy				(crx_drdy));		 // Templated

  /* sd_fifo_b AUTO_TEMPLATE "fifo_\(.*\)"
   (
    .p_abort  (1'b0),
    .p_commit (1'b0),
    .c_usage    (@_usage),
    .p_usage    (),
    .c_\(.*\)     (c@_\1),
    .p_\(.*\)    (p@_\1),
   );
   */
  sd_fifo_b #(`PFW_SZ, `RX_FIFO_DEPTH, 0, 1) fifo_rx
    (/*AUTOINST*/
     // Outputs
     .c_drdy				(crx_drdy),		 // Templated
     .p_srdy				(prx_srdy),		 // Templated
     .p_data				(prx_data),		 // Templated
     .p_usage				(),			 // Templated
     .c_usage				(rx_usage),		 // Templated
     // Inputs
     .clk				(clk),
     .reset				(reset),
     .c_srdy				(crx_srdy),		 // Templated
     .c_commit				(crx_commit),		 // Templated
     .c_abort				(crx_abort),		 // Templated
     .c_data				(crx_data),		 // Templated
     .p_drdy				(prx_drdy),		 // Templated
     .p_commit				(1'b0),			 // Templated
     .p_abort				(1'b0));			 // Templated

  sd_fifo_b #(`PFW_SZ, `TX_FIFO_DEPTH, 0, 1) fifo_tx
    (/*AUTOINST*/
     // Outputs
     .c_drdy				(ctx_drdy),		 // Templated
     .p_srdy				(ptx_srdy),		 // Templated
     .p_data				(ptx_data),		 // Templated
     .p_usage				(),			 // Templated
     .c_usage				(tx_usage),		 // Templated
     // Inputs
     .clk				(clk),
     .reset				(reset),
     .c_srdy				(ctx_srdy),		 // Templated
     .c_commit				(ctx_commit),		 // Templated
     .c_abort				(ctx_abort),		 // Templated
     .c_data				(ctx_data),		 // Templated
     .p_drdy				(ptx_drdy),		 // Templated
     .p_commit				(1'b0),			 // Templated
     .p_abort				(1'b0));			 // Templated

/* port_ring_tap AUTO_TEMPLATE
 (
    .ro_data				(ro_data[`PRW_SZ-1:0]),
    .ri_data				(ri_data[`PRW_SZ-1:0]),
    .prx_\(.*\)    (prx_\1),
    .ptx_\(.*\)    (rttx_\1),
  );
 */
  port_ring_tap #(port_num) ring_tap
    (/*AUTOINST*/
     // Outputs
     .ri_drdy				(ri_drdy),
     .prx_drdy				(prx_drdy),		 // Templated
     .ro_srdy				(ro_srdy),
     .ro_data				(ro_data[`PRW_SZ-1:0]),	 // Templated
     .ptx_srdy				(rttx_srdy),		 // Templated
     .ptx_data				(rttx_data),		 // Templated
     .fli_drdy				(fli_drdy),
     .rarb_req				(rarb_req),
     // Inputs
     .clk				(clk),
     .reset				(reset),
     .ri_srdy				(ri_srdy),
     .ri_data				(ri_data[`PRW_SZ-1:0]),	 // Templated
     .prx_srdy				(prx_srdy),		 // Templated
     .prx_data				(prx_data),		 // Templated
     .ro_drdy				(ro_drdy),
     .ptx_drdy				(rttx_drdy),		 // Templated
     .fli_srdy				(fli_srdy),
     .fli_data				(fli_data[`NUM_PORTS-1:0]),
     .rarb_ack				(rarb_ack));

/* egr_oflow AUTO_TEMPLATE
 (
    .c_\(.*\)    (rttx_\1[]),
    .p_\(.*\)    (ctx_\1[]),
  );
 */
  egr_oflow oflow
    (/*AUTOINST*/
     // Outputs
     .c_drdy				(rttx_drdy),		 // Templated
     .p_srdy				(ctx_srdy),		 // Templated
     .p_data				(ctx_data[`PFW_SZ-1:0]), // Templated
     .p_commit				(ctx_commit),		 // Templated
     .p_abort				(ctx_abort),		 // Templated
     // Inputs
     .clk				(clk),
     .reset				(reset),
     .c_srdy				(rttx_srdy),		 // Templated
     .c_data				(rttx_data[`PFW_SZ-1:0]), // Templated
     .tx_usage				(tx_usage[`TX_USG_SZ-1:0]),
     .p_drdy				(ctx_drdy));		 // Templated

/* distributor AUTO_TEMPLATE
 (
    .p_\(.*\)    (txg_\1[]),
 );
 */
  distributor dst
    (/*AUTOINST*/
     // Outputs
     .ptx_drdy				(ptx_drdy),
     .p_srdy				(txg_srdy),		 // Templated
     .p_code				(txg_code[1:0]),	 // Templated
     .p_data				(txg_data[7:0]),	 // Templated
     // Inputs
     .clk				(clk),
     .reset				(reset),
     .ptx_srdy				(ptx_srdy),
     .ptx_data				(ptx_data[`PFW_SZ-1:0]),
     .p_drdy				(txg_drdy));		 // Templated

  sd_tx_gigmac tx_gmii
    (/*AUTOINST*/
     // Outputs
     .gmii_tx_en			(gmii_tx_en),
     .gmii_txd				(gmii_txd[7:0]),
     .txg_drdy				(txg_drdy),
     // Inputs
     .clk				(clk),
     .reset				(reset),
     .txg_srdy				(txg_srdy),
     .txg_code				(txg_code[1:0]),
     .txg_data				(txg_data[7:0]));
  
endmodule // port_macro
// Local Variables:
// verilog-library-directories:("." "../../../rtl/verilog/closure" "../../../rtl/verilog/buffers" "../../../rtl/verilog/forks")
// End:  
