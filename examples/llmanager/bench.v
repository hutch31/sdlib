`timescale 1ns/1ns

module bench;

  localparam sources = 4;
  localparam sinks = 4;
  localparam sksz  = 2;
  localparam lpsz = 4;
  localparam lpdsz = 5;
  localparam pages = 16;
  localparam refsz = 3;
  localparam maxref = 4;

  reg   clk;
  reg   reset;
  integer bfree;
  integer packets;
  event   free_list;

  initial packets = 0;

   /*AUTOWIRE*/
   // Beginning of automatic wires (for undeclared instantiated-module outputs)
   wire [3:0]           done;                   // From rport0 of llrdport.v, ...
   wire [(sinks)-1:0]   drf_drdy;               // From lm of llmanager.v
   wire [31:0]          drf_page_list;          // From wport0 of llwrport.v, ...
   wire [3:0]           drf_srdy;               // From wport0 of llwrport.v, ...
   wire [(lpsz):0]      free_count;             // From lm of llmanager.v
   wire [3:0]           ip_drdy;                // From fibstub of fibstub.v
   wire [(lpsz)-1:0]    ip_page0;               // From rport0 of llrdport.v
   wire [(lpsz)-1:0]    ip_page1;               // From rport1 of llrdport.v
   wire [(lpsz)-1:0]    ip_page2;               // From rport2 of llrdport.v
   wire [(lpsz)-1:0]    ip_page3;               // From rport3 of llrdport.v
   wire [3:0]           ip_srdy;                // From rport0 of llrdport.v, ...
   wire [(sources)-1:0] lnp_drdy;               // From lm of llmanager.v
   wire [35:0]          lnp_pnp;                // From rport0 of llrdport.v, ...
   wire [3:0]           lnp_srdy;               // From rport0 of llrdport.v, ...
   wire [3:0]           op_drdy;                // From wport0 of llwrport.v, ...
   wire [(lpsz)-1:0]    op_page0;               // From fibstub of fibstub.v
   wire [(lpsz)-1:0]    op_page1;               // From fibstub of fibstub.v
   wire [(lpsz)-1:0]    op_page2;               // From fibstub of fibstub.v
   wire [(lpsz)-1:0]    op_page3;               // From fibstub of fibstub.v
   wire [3:0]           op_srdy;                // From fibstub of fibstub.v
   wire [(sources)-1:0] par_drdy;               // From lm of llmanager.v
   wire [3:0]           par_srdy;               // From rport0 of llrdport.v, ...
   wire [3:0]           parr_drdy;              // From rport0 of llrdport.v, ...
   wire [(lpsz)-1:0]    parr_page;              // From lm of llmanager.v
   wire [(sources)-1:0] parr_srdy;              // From lm of llmanager.v
   wire [(lpsz)-1:0]    pgmem_rd_addr;          // From lm of llmanager.v
   wire [(lpdsz)-1:0]   pgmem_rd_data;          // From pglist_mem of behave2p_mem.v
   wire                 pgmem_rd_en;            // From lm of llmanager.v
   wire [(lpsz)-1:0]    pgmem_wr_addr;          // From lm of llmanager.v
   wire [(lpdsz)-1:0]   pgmem_wr_data;          // From lm of llmanager.v
   wire                 pgmem_wr_en;            // From lm of llmanager.v
   wire [(lpsz)-1:0]    ref_rd_addr;            // From lm of llmanager.v
   wire [(refsz)-1:0]   ref_rd_data;            // From ref_mem of behave2p_mem.v
   wire                 ref_rd_en;              // From lm of llmanager.v
   wire [(lpsz)-1:0]    ref_wr_addr;            // From lm of llmanager.v
   wire [(refsz)-1:0]   ref_wr_data;            // From lm of llmanager.v
   wire                 ref_wr_en;              // From lm of llmanager.v
   wire [(refsz)-1:0]   refup_count;            // From fibstub of fibstub.v
   wire                 refup_drdy;             // From lm of llmanager.v
   wire [(lpsz)-1:0]    refup_page;             // From fibstub of fibstub.v
   wire                 refup_srdy;             // From fibstub of fibstub.v
   wire [(sinks)-1:0]   rlp_drdy;               // From lm of llmanager.v
   wire [15:0]          rlp_rd_page;            // From wport0 of llwrport.v, ...
   wire [3:0]           rlp_srdy;               // From wport0 of llwrport.v, ...
   wire [(lpdsz)-1:0]   rlpr_data;              // From lm of llmanager.v
   wire [3:0]           rlpr_drdy;              // From wport0 of llwrport.v, ...
   wire [(sinks)-1:0]   rlpr_srdy;              // From lm of llmanager.v
   // End of automatics

  initial
    begin
      $timeformat(-9, 0, " ns", 5);
      $dumpfile ("bench.vcd");
      $dumpvars;
      clk = 0;
      reset = 1;
      #100;
      reset = 0;
      wait (done == {4{1'b1}});
      #10000;
      walk_free_list;
      $finish;
    end

  always clk = #5 ~clk;

  always @(negedge clk)
    bfree = instant_walk_free(reset);

/* behave2p_mem AUTO_TEMPLATE
 (

     .wr_clk         (clk),
     .rd_clk         (clk),

     .wr_en          (pgmem_wr_en),
     .d_in           (pgmem_wr_data[]),
     .wr_addr        (pgmem_wr_addr[]),

     .rd_en          (pgmem_rd_en),
     .rd_addr        (pgmem_rd_addr[]),
     .d_out          (pgmem_rd_data[]),
 ); 
 */
  behave2p_mem #(.depth   (pages), 
                 .addr_sz (lpsz),
                 .width   (lpdsz)) pglist_mem
    (/*AUTOINST*/
     // Outputs
     .d_out                             (pgmem_rd_data[(lpdsz)-1:0]), // Templated
     // Inputs
     .wr_en                             (pgmem_wr_en),           // Templated
     .rd_en                             (pgmem_rd_en),           // Templated
     .wr_clk                            (clk),                   // Templated
     .rd_clk                            (clk),                   // Templated
     .d_in                              (pgmem_wr_data[(lpdsz)-1:0]), // Templated
     .rd_addr                           (pgmem_rd_addr[(lpsz)-1:0]), // Templated
     .wr_addr                           (pgmem_wr_addr[(lpsz)-1:0])); // Templated

/* behave2p_mem AUTO_TEMPLATE
 (

     .wr_clk         (clk),
     .rd_clk         (clk),

     .wr_en          (ref_wr_en),
     .d_in           (ref_wr_data[]),
     .wr_addr        (ref_wr_addr[]),

     .rd_en          (ref_rd_en),
     .rd_addr        (ref_rd_addr[]),
     .d_out          (ref_rd_data[]),
 ); 
 */
  behave2p_mem #(.depth   (pages), 
                 .addr_sz (lpsz),
                 .width   (refsz)) ref_mem
    (/*AUTOINST*/
     // Outputs
     .d_out                             (ref_rd_data[(refsz)-1:0]), // Templated
     // Inputs
     .wr_en                             (ref_wr_en),             // Templated
     .rd_en                             (ref_rd_en),             // Templated
     .wr_clk                            (clk),                   // Templated
     .rd_clk                            (clk),                   // Templated
     .d_in                              (ref_wr_data[(refsz)-1:0]), // Templated
     .rd_addr                           (ref_rd_addr[(lpsz)-1:0]), // Templated
     .wr_addr                           (ref_wr_addr[(lpsz)-1:0])); // Templated

/* llmanager AUTO_TEMPLATE
 (
     .lnp_pnp                           (lnp_pnp[35:0]),
 
     .drf_page_list                     (drf_page_list[sinks*lpsz*2-1:0]),
 );
 */
  llmanager #(
              // Parameters
              .lpsz                     (lpsz),
              .lpdsz                    (lpdsz),
              .pages                    (pages),
              .sources                  (sources),
              .maxref                   (maxref),
              .refsz                    (refsz),
              .sinks                    (sinks),
              .sksz                     (sksz)) lm
    (/*AUTOINST*/
     // Outputs
     .par_drdy                          (par_drdy[(sources)-1:0]),
     .parr_srdy                         (parr_srdy[(sources)-1:0]),
     .parr_page                         (parr_page[(lpsz)-1:0]),
     .lnp_drdy                          (lnp_drdy[(sources)-1:0]),
     .rlp_drdy                          (rlp_drdy[(sinks)-1:0]),
     .rlpr_srdy                         (rlpr_srdy[(sinks)-1:0]),
     .rlpr_data                         (rlpr_data[(lpdsz)-1:0]),
     .drf_drdy                          (drf_drdy[(sinks)-1:0]),
     .refup_drdy                        (refup_drdy),
     .pgmem_wr_en                       (pgmem_wr_en),
     .pgmem_wr_addr                     (pgmem_wr_addr[(lpsz)-1:0]),
     .pgmem_wr_data                     (pgmem_wr_data[(lpdsz)-1:0]),
     .pgmem_rd_addr                     (pgmem_rd_addr[(lpsz)-1:0]),
     .pgmem_rd_en                       (pgmem_rd_en),
     .ref_wr_en                         (ref_wr_en),
     .ref_wr_addr                       (ref_wr_addr[(lpsz)-1:0]),
     .ref_wr_data                       (ref_wr_data[(refsz)-1:0]),
     .ref_rd_addr                       (ref_rd_addr[(lpsz)-1:0]),
     .ref_rd_en                         (ref_rd_en),
     .free_count                        (free_count[(lpsz):0]),
     // Inputs
     .clk                               (clk),
     .reset                             (reset),
     .par_srdy                          (par_srdy[(sources)-1:0]),
     .parr_drdy                         (parr_drdy[(sources)-1:0]),
     .lnp_srdy                          (lnp_srdy[(sources)-1:0]),
     .lnp_pnp                           (lnp_pnp[35:0]),         // Templated
     .rlp_srdy                          (rlp_srdy[(sinks)-1:0]),
     .rlp_rd_page                       (rlp_rd_page[(sinks)*(lpsz)-1:0]),
     .rlpr_drdy                         (rlpr_drdy[(sinks)-1:0]),
     .drf_srdy                          (drf_srdy[(sinks)-1:0]),
     .drf_page_list                     (drf_page_list[sinks*lpsz*2-1:0]), // Templated
     .refup_srdy                        (refup_srdy),
     .refup_page                        (refup_page[(lpsz)-1:0]),
     .refup_count                       (refup_count[(refsz)-1:0]),
     .pgmem_rd_data                     (pgmem_rd_data[(lpdsz)-1:0]),
     .ref_rd_data                       (ref_rd_data[(refsz)-1:0]));

/* llrdport AUTO_TEMPLATE
 (
     .ip_srdy                           (ip_srdy[@]),
     .ip_drdy                           (ip_drdy[@]),
     .ip_page                           (ip_page@[(lpsz)-1:0]),
 
     .par_srdy                             (par_srdy[@]),
     .par_drdy                             (par_drdy[@]),
 
     .parr_srdy                         (parr_srdy[@]),
     .parr_drdy                         (parr_drdy[@]),
 
     .lnp_srdy                          (lnp_srdy[@]),
     .lnp_drdy                          (lnp_drdy[@]),
     .lnp_pnp                           (lnp_pnp[@"(- (* (+ @ 1) 9) 1)":@"(* @ 9)"]),
 
     .done                              (done[@]),
 );
 */
 llrdport #(/*AUTOINSTPARAM*/
            // Parameters
            .lpsz                       (lpsz),
            .lpdsz                      (lpdsz),
            .sources                    (sources)) rport0
    (/*AUTOINST*/
     // Outputs
     .par_srdy                          (par_srdy[0]),           // Templated
     .parr_drdy                         (parr_drdy[0]),          // Templated
     .lnp_srdy                          (lnp_srdy[0]),           // Templated
     .lnp_pnp                           (lnp_pnp[8:0]),          // Templated
     .ip_srdy                           (ip_srdy[0]),            // Templated
     .ip_page                           (ip_page0[(lpsz)-1:0]),  // Templated
     .done                              (done[0]),               // Templated
     // Inputs
     .clk                               (clk),
     .reset                             (reset),
     .par_drdy                          (par_drdy[0]),           // Templated
     .parr_srdy                         (parr_srdy[0]),          // Templated
     .parr_page                         (parr_page[(lpsz)-1:0]),
     .lnp_drdy                          (lnp_drdy[0]),           // Templated
     .ip_drdy                           (ip_drdy[0]));            // Templated

  llrdport #(/*AUTOINSTPARAM*/
             // Parameters
             .lpsz                      (lpsz),
             .lpdsz                     (lpdsz),
             .sources                   (sources)) rport1
    (/*AUTOINST*/
     // Outputs
     .par_srdy                          (par_srdy[1]),           // Templated
     .parr_drdy                         (parr_drdy[1]),          // Templated
     .lnp_srdy                          (lnp_srdy[1]),           // Templated
     .lnp_pnp                           (lnp_pnp[17:9]),         // Templated
     .ip_srdy                           (ip_srdy[1]),            // Templated
     .ip_page                           (ip_page1[(lpsz)-1:0]),  // Templated
     .done                              (done[1]),               // Templated
     // Inputs
     .clk                               (clk),
     .reset                             (reset),
     .par_drdy                          (par_drdy[1]),           // Templated
     .parr_srdy                         (parr_srdy[1]),          // Templated
     .parr_page                         (parr_page[(lpsz)-1:0]),
     .lnp_drdy                          (lnp_drdy[1]),           // Templated
     .ip_drdy                           (ip_drdy[1]));            // Templated

  llrdport #(/*AUTOINSTPARAM*/
             // Parameters
             .lpsz                      (lpsz),
             .lpdsz                     (lpdsz),
             .sources                   (sources)) rport2
    (/*AUTOINST*/
     // Outputs
     .par_srdy                          (par_srdy[2]),           // Templated
     .parr_drdy                         (parr_drdy[2]),          // Templated
     .lnp_srdy                          (lnp_srdy[2]),           // Templated
     .lnp_pnp                           (lnp_pnp[26:18]),        // Templated
     .ip_srdy                           (ip_srdy[2]),            // Templated
     .ip_page                           (ip_page2[(lpsz)-1:0]),  // Templated
     .done                              (done[2]),               // Templated
     // Inputs
     .clk                               (clk),
     .reset                             (reset),
     .par_drdy                          (par_drdy[2]),           // Templated
     .parr_srdy                         (parr_srdy[2]),          // Templated
     .parr_page                         (parr_page[(lpsz)-1:0]),
     .lnp_drdy                          (lnp_drdy[2]),           // Templated
     .ip_drdy                           (ip_drdy[2]));            // Templated

  llrdport #(/*AUTOINSTPARAM*/
             // Parameters
             .lpsz                      (lpsz),
             .lpdsz                     (lpdsz),
             .sources                   (sources)) rport3
    (/*AUTOINST*/
     // Outputs
     .par_srdy                          (par_srdy[3]),           // Templated
     .parr_drdy                         (parr_drdy[3]),          // Templated
     .lnp_srdy                          (lnp_srdy[3]),           // Templated
     .lnp_pnp                           (lnp_pnp[35:27]),        // Templated
     .ip_srdy                           (ip_srdy[3]),            // Templated
     .ip_page                           (ip_page3[(lpsz)-1:0]),  // Templated
     .done                              (done[3]),               // Templated
     // Inputs
     .clk                               (clk),
     .reset                             (reset),
     .par_drdy                          (par_drdy[3]),           // Templated
     .parr_srdy                         (parr_srdy[3]),          // Templated
     .parr_page                         (parr_page[(lpsz)-1:0]),
     .lnp_drdy                          (lnp_drdy[3]),           // Templated
     .ip_drdy                           (ip_drdy[3]));            // Templated

/* llwrport AUTO_TEMPLATE
 (
     .op_srdy                           (op_srdy[@]),
     .op_drdy                           (op_drdy[@]),
     .op_page                           (op_page@[(lpsz)-1:0]),
 
     .rlp_srdy                          (rlp_srdy[@]),
     .rlp_drdy                          (rlp_drdy[@]),
     .rlp_rd_page                       (rlp_rd_page[@"(- (* (+ @ 1) 4) 1)":@"(* @ 4)"]),
 
     .rlpr_srdy                         (rlpr_srdy[@]),
     .rlpr_drdy                         (rlpr_drdy[@]),
     .rlpr_data                         (rlpr_data[lpdsz-1:0]),
 
     .drf_srdy                         (drf_srdy[@]),
     .drf_drdy                         (drf_drdy[@]),
     .drf_page_list                    (drf_page_list[@"(- (* (+ @ 1) 8) 1)":@"(* @ 8)"]),
  );
 */
  llwrport #(/*AUTOINSTPARAM*/
             // Parameters
             .lpsz                      (lpsz),
             .lpdsz                     (lpdsz),
             .sinks                     (sinks)) wport0
    (/*AUTOINST*/
     // Outputs
     .op_drdy                           (op_drdy[0]),            // Templated
     .rlp_srdy                          (rlp_srdy[0]),           // Templated
     .rlp_rd_page                       (rlp_rd_page[3:0]),      // Templated
     .rlpr_drdy                         (rlpr_drdy[0]),          // Templated
     .drf_srdy                          (drf_srdy[0]),           // Templated
     .drf_page_list                     (drf_page_list[7:0]),    // Templated
     // Inputs
     .clk                               (clk),
     .reset                             (reset),
     .op_srdy                           (op_srdy[0]),            // Templated
     .op_page                           (op_page0[(lpsz)-1:0]),  // Templated
     .rlp_drdy                          (rlp_drdy[0]),           // Templated
     .rlpr_srdy                         (rlpr_srdy[0]),          // Templated
     .rlpr_data                         (rlpr_data[lpdsz-1:0]),  // Templated
     .drf_drdy                          (drf_drdy[0]));           // Templated

  llwrport #(/*AUTOINSTPARAM*/
             // Parameters
             .lpsz                      (lpsz),
             .lpdsz                     (lpdsz),
             .sinks                     (sinks)) wport1
    (/*AUTOINST*/
     // Outputs
     .op_drdy                           (op_drdy[1]),            // Templated
     .rlp_srdy                          (rlp_srdy[1]),           // Templated
     .rlp_rd_page                       (rlp_rd_page[7:4]),      // Templated
     .rlpr_drdy                         (rlpr_drdy[1]),          // Templated
     .drf_srdy                          (drf_srdy[1]),           // Templated
     .drf_page_list                     (drf_page_list[15:8]),   // Templated
     // Inputs
     .clk                               (clk),
     .reset                             (reset),
     .op_srdy                           (op_srdy[1]),            // Templated
     .op_page                           (op_page1[(lpsz)-1:0]),  // Templated
     .rlp_drdy                          (rlp_drdy[1]),           // Templated
     .rlpr_srdy                         (rlpr_srdy[1]),          // Templated
     .rlpr_data                         (rlpr_data[lpdsz-1:0]),  // Templated
     .drf_drdy                          (drf_drdy[1]));           // Templated

  llwrport #(/*AUTOINSTPARAM*/
             // Parameters
             .lpsz                      (lpsz),
             .lpdsz                     (lpdsz),
             .sinks                     (sinks)) wport2
    (/*AUTOINST*/
     // Outputs
     .op_drdy                           (op_drdy[2]),            // Templated
     .rlp_srdy                          (rlp_srdy[2]),           // Templated
     .rlp_rd_page                       (rlp_rd_page[11:8]),     // Templated
     .rlpr_drdy                         (rlpr_drdy[2]),          // Templated
     .drf_srdy                          (drf_srdy[2]),           // Templated
     .drf_page_list                     (drf_page_list[23:16]),  // Templated
     // Inputs
     .clk                               (clk),
     .reset                             (reset),
     .op_srdy                           (op_srdy[2]),            // Templated
     .op_page                           (op_page2[(lpsz)-1:0]),  // Templated
     .rlp_drdy                          (rlp_drdy[2]),           // Templated
     .rlpr_srdy                         (rlpr_srdy[2]),          // Templated
     .rlpr_data                         (rlpr_data[lpdsz-1:0]),  // Templated
     .drf_drdy                          (drf_drdy[2]));           // Templated

  llwrport #(/*AUTOINSTPARAM*/
             // Parameters
             .lpsz                      (lpsz),
             .lpdsz                     (lpdsz),
             .sinks                     (sinks)) wport3
    (/*AUTOINST*/
     // Outputs
     .op_drdy                           (op_drdy[3]),            // Templated
     .rlp_srdy                          (rlp_srdy[3]),           // Templated
     .rlp_rd_page                       (rlp_rd_page[15:12]),    // Templated
     .rlpr_drdy                         (rlpr_drdy[3]),          // Templated
     .drf_srdy                          (drf_srdy[3]),           // Templated
     .drf_page_list                     (drf_page_list[31:24]),  // Templated
     // Inputs
     .clk                               (clk),
     .reset                             (reset),
     .op_srdy                           (op_srdy[3]),            // Templated
     .op_page                           (op_page3[(lpsz)-1:0]),  // Templated
     .rlp_drdy                          (rlp_drdy[3]),           // Templated
     .rlpr_srdy                         (rlpr_srdy[3]),          // Templated
     .rlpr_data                         (rlpr_data[lpdsz-1:0]),  // Templated
     .drf_drdy                          (drf_drdy[3]));           // Templated

  fibstub #(/*AUTOINSTPARAM*/
            // Parameters
            .lpsz                       (lpsz),
            .refsz                      (refsz),
            .maxref                     (maxref)) fibstub
    (/*AUTOINST*/
     // Outputs
     .ip_drdy                           (ip_drdy[3:0]),
     .op_srdy                           (op_srdy[3:0]),
     .op_page0                          (op_page0[(lpsz)-1:0]),
     .op_page1                          (op_page1[(lpsz)-1:0]),
     .op_page2                          (op_page2[(lpsz)-1:0]),
     .op_page3                          (op_page3[(lpsz)-1:0]),
     .refup_srdy                        (refup_srdy),
     .refup_page                        (refup_page[(lpsz)-1:0]),
     .refup_count                       (refup_count[(refsz)-1:0]),
     // Inputs
     .clk                               (clk),
     .reset                             (reset),
     .ip_srdy                           (ip_srdy[3:0]),
     .ip_page0                          (ip_page0[(lpsz)-1:0]),
     .ip_page1                          (ip_page1[(lpsz)-1:0]),
     .ip_page2                          (ip_page2[(lpsz)-1:0]),
     .ip_page3                          (ip_page3[(lpsz)-1:0]),
     .op_drdy                           (op_drdy[3:0]),
     .refup_drdy                        (refup_drdy));

  function [31:0] instant_walk_free;
    input foo;
    integer free_count;
    integer head, tail;
    begin
      free_count = 0;
      head = lm.free_head_ptr;
      tail = lm.free_tail_ptr;

      if (foo == 1)
        begin
          instant_walk_free = 0;
        end
      else
        begin
          while ((head != tail) && (free_count <= pages))
            begin
              free_count = free_count + 1;
              head = pglist_mem.array[head];
            end // while (head != tail)
          instant_walk_free = free_count;
        end
    end
  endfunction // if

  task print_free_list;
    integer head, tail;
    begin
      head = lm.free_head_ptr;
      tail = lm.free_tail_ptr;
 
      $write ("%t: Free list=%0d", $time, head);
      while (head != tail)
        begin
          head = pglist_mem.array[head];
          $write ("->%0d", head);
        end
      $display ("");
    end
  endtask // print_free_list

  always @(free_list)
    print_free_list;
      

  task walk_free_list;
    integer free_count;
    integer head, tail;
    reg [pages-1:0] plist;
    begin
      free_count = 0;
      head = lm.free_head_ptr;
      tail = lm.free_tail_ptr;
      plist = 0;

      $display ("Free list head=%0d, tail=%0d", head, tail);
      while (head != tail)
        begin
          free_count = free_count + 1;
          head = pglist_mem.array[head];
          if (plist[head] !== 0)
            $display ("Duplicate page #%d", head);
          else
            plist[head] = 1;

          //if (free_count > 300) break;
        end
      $display ("Free count=%d", free_count);
      $display ("Page list=%b", plist);
    end
  endtask

endmodule // bench
// Local Variables:
// verilog-library-directories:("." "../../rtl/verilog/memory")
// End:
