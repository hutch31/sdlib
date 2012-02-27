`timescale 1ns/1ns

module bench;

  localparam sources = 4;
  localparam sinks = 4;
  localparam sksz  = 2;
  localparam lpsz = 3;
  localparam lpdsz = 4;
  localparam pages = 8;

  reg   clk;
  reg   reset;
  integer bfree;

  /*AUTOWIRE*/
  // Beginning of automatic wires (for undeclared instantiated-module outputs)
  wire [(lpsz):0]       free_count;             // From lm of llmanager.v
  wire [(sources)-1:0]  lnp_drdy;               // From lm of llmanager.v
  wire [27:0]           lnp_pnp;                // From rport0 of llrdport.v, ...
  wire [3:0]            lnp_srdy;               // From rport0 of llrdport.v, ...
  wire [3:0]            lprq_drdy;              // From rport0 of llrdport.v, ...
  wire [(lpsz)-1:0]     lprq_page;              // From lm of llmanager.v
  wire [(sources)-1:0]  lprq_srdy;              // From lm of llmanager.v
  wire [(sinks)-1:0]    lprt_drdy;              // From lm of llmanager.v
  wire [11:0]           lprt_page_list;         // From wport0 of llwrport.v, ...
  wire [3:0]            lprt_srdy;              // From wport0 of llwrport.v, ...
  wire                  op_drdy0;               // From wport0 of llwrport.v
  wire                  op_drdy1;               // From wport1 of llwrport.v
  wire                  op_drdy2;               // From wport2 of llwrport.v
  wire                  op_drdy3;               // From wport3 of llwrport.v
  wire [(lpsz)-1:0]     op_page0;               // From rport0 of llrdport.v
  wire [(lpsz)-1:0]     op_page1;               // From rport1 of llrdport.v
  wire [(lpsz)-1:0]     op_page2;               // From rport2 of llrdport.v
  wire [(lpsz)-1:0]     op_page3;               // From rport3 of llrdport.v
  wire                  op_srdy0;               // From rport0 of llrdport.v
  wire                  op_srdy1;               // From rport1 of llrdport.v
  wire                  op_srdy2;               // From rport2 of llrdport.v
  wire                  op_srdy3;               // From rport3 of llrdport.v
  wire [(sources)-1:0]  pgack;                  // From lm of llmanager.v
  wire [3:0]            pgreq;                  // From rport0 of llrdport.v, ...
  wire [(sinks)-1:0]    rlp_drdy;               // From lm of llmanager.v
  wire [11:0]           rlp_rd_page;            // From wport0 of llwrport.v, ...
  wire [3:0]            rlp_srdy;               // From wport0 of llwrport.v, ...
  wire [(lpdsz)-1:0]    rlpd_data;              // From lm of llmanager.v
  wire [3:0]            rlpd_drdy;              // From wport0 of llwrport.v, ...
  wire [(sinks)-1:0]    rlpd_srdy;              // From lm of llmanager.v
  // End of automatics

  initial
    begin
      $dumpfile ("bench.vcd");
      $dumpvars;
      clk = 0;
      reset = 1;
      #100;
      reset = 0;
      #50000;
      walk_free_list;
      $finish;
    end

  always clk = #5 ~clk;

  always @(negedge clk)
    bfree = instant_walk_free(reset);

/* llmanager AUTO_TEMPLATE
 (
     .lnp_pnp                           (lnp_pnp[27:0]),
 );
 */
  llmanager #(
              // Parameters
              .lpsz                     (lpsz),
              .lpdsz                    (lpdsz),
              .pages                    (pages),
              .sources                  (sources),
              .sinks                    (sinks),
              .sksz                     (sksz)) lm
    (/*AUTOINST*/
     // Outputs
     .pgack                             (pgack[(sources)-1:0]),
     .lprq_srdy                         (lprq_srdy[(sources)-1:0]),
     .lprq_page                         (lprq_page[(lpsz)-1:0]),
     .lnp_drdy                          (lnp_drdy[(sources)-1:0]),
     .rlp_drdy                          (rlp_drdy[(sinks)-1:0]),
     .rlpd_srdy                         (rlpd_srdy[(sinks)-1:0]),
     .rlpd_data                         (rlpd_data[(lpdsz)-1:0]),
     .lprt_drdy                         (lprt_drdy[(sinks)-1:0]),
     .free_count                        (free_count[(lpsz):0]),
     // Inputs
     .clk                               (clk),
     .reset                             (reset),
     .pgreq                             (pgreq[(sources)-1:0]),
     .lprq_drdy                         (lprq_drdy[(sources)-1:0]),
     .lnp_srdy                          (lnp_srdy[(sources)-1:0]),
     .lnp_pnp                           (lnp_pnp[27:0]),         // Templated
     .rlp_srdy                          (rlp_srdy[(sinks)-1:0]),
     .rlp_rd_page                       (rlp_rd_page[(sinks)*(lpsz)-1:0]),
     .rlpd_drdy                         (rlpd_drdy[(sinks)-1:0]),
     .lprt_srdy                         (lprt_srdy[(sinks)-1:0]),
     .lprt_page_list                    (lprt_page_list[(sinks)*(lpsz)-1:0]));

/* llrdport AUTO_TEMPLATE
 (
     .op_srdy                           (op_srdy@),
     .op_drdy                           (op_drdy@),
     .op_page                           (op_page@[(lpsz)-1:0]),
 
     .pgreq                             (pgreq[@]),
     .pgack                             (pgack[@]),
 
     .lprq_srdy                         (lprq_srdy[@]),
     .lprq_drdy                         (lprq_drdy[@]),
 
     .lnp_srdy                          (lnp_srdy[@]),
     .lnp_drdy                          (lnp_drdy[@]),
     .lnp_pnp                           (lnp_pnp[@"(- (* (+ @ 1) 7) 1)":@"(* @ 7)"]),
 );
 */
 llrdport #(/*AUTOINSTPARAM*/
            // Parameters
            .lpsz                       (lpsz),
            .lpdsz                      (lpdsz),
            .sources                    (sources)) rport0
    (/*AUTOINST*/
     // Outputs
     .pgreq                             (pgreq[0]),              // Templated
     .lprq_drdy                         (lprq_drdy[0]),          // Templated
     .lnp_srdy                          (lnp_srdy[0]),           // Templated
     .lnp_pnp                           (lnp_pnp[6:0]),          // Templated
     .op_srdy                           (op_srdy0),              // Templated
     .op_page                           (op_page0[(lpsz)-1:0]),  // Templated
     // Inputs
     .clk                               (clk),
     .reset                             (reset),
     .pgack                             (pgack[0]),              // Templated
     .lprq_srdy                         (lprq_srdy[0]),          // Templated
     .lprq_page                         (lprq_page[(lpsz)-1:0]),
     .lnp_drdy                          (lnp_drdy[0]),           // Templated
     .op_drdy                           (op_drdy0));              // Templated

  llrdport #(/*AUTOINSTPARAM*/
             // Parameters
             .lpsz                      (lpsz),
             .lpdsz                     (lpdsz),
             .sources                   (sources)) rport1
    (/*AUTOINST*/
     // Outputs
     .pgreq                             (pgreq[1]),              // Templated
     .lprq_drdy                         (lprq_drdy[1]),          // Templated
     .lnp_srdy                          (lnp_srdy[1]),           // Templated
     .lnp_pnp                           (lnp_pnp[13:7]),         // Templated
     .op_srdy                           (op_srdy1),              // Templated
     .op_page                           (op_page1[(lpsz)-1:0]),  // Templated
     // Inputs
     .clk                               (clk),
     .reset                             (reset),
     .pgack                             (pgack[1]),              // Templated
     .lprq_srdy                         (lprq_srdy[1]),          // Templated
     .lprq_page                         (lprq_page[(lpsz)-1:0]),
     .lnp_drdy                          (lnp_drdy[1]),           // Templated
     .op_drdy                           (op_drdy1));              // Templated

  llrdport #(/*AUTOINSTPARAM*/
             // Parameters
             .lpsz                      (lpsz),
             .lpdsz                     (lpdsz),
             .sources                   (sources)) rport2
    (/*AUTOINST*/
     // Outputs
     .pgreq                             (pgreq[2]),              // Templated
     .lprq_drdy                         (lprq_drdy[2]),          // Templated
     .lnp_srdy                          (lnp_srdy[2]),           // Templated
     .lnp_pnp                           (lnp_pnp[20:14]),        // Templated
     .op_srdy                           (op_srdy2),              // Templated
     .op_page                           (op_page2[(lpsz)-1:0]),  // Templated
     // Inputs
     .clk                               (clk),
     .reset                             (reset),
     .pgack                             (pgack[2]),              // Templated
     .lprq_srdy                         (lprq_srdy[2]),          // Templated
     .lprq_page                         (lprq_page[(lpsz)-1:0]),
     .lnp_drdy                          (lnp_drdy[2]),           // Templated
     .op_drdy                           (op_drdy2));              // Templated

  llrdport #(/*AUTOINSTPARAM*/
             // Parameters
             .lpsz                      (lpsz),
             .lpdsz                     (lpdsz),
             .sources                   (sources)) rport3
    (/*AUTOINST*/
     // Outputs
     .pgreq                             (pgreq[3]),              // Templated
     .lprq_drdy                         (lprq_drdy[3]),          // Templated
     .lnp_srdy                          (lnp_srdy[3]),           // Templated
     .lnp_pnp                           (lnp_pnp[27:21]),        // Templated
     .op_srdy                           (op_srdy3),              // Templated
     .op_page                           (op_page3[(lpsz)-1:0]),  // Templated
     // Inputs
     .clk                               (clk),
     .reset                             (reset),
     .pgack                             (pgack[3]),              // Templated
     .lprq_srdy                         (lprq_srdy[3]),          // Templated
     .lprq_page                         (lprq_page[(lpsz)-1:0]),
     .lnp_drdy                          (lnp_drdy[3]),           // Templated
     .op_drdy                           (op_drdy3));              // Templated

/* llwrport AUTO_TEMPLATE
 (
     .op_srdy                           (op_srdy@),
     .op_drdy                           (op_drdy@),
     .op_page                           (op_page@[(lpsz)-1:0]),
 
     .rlp_srdy                          (rlp_srdy[@]),
     .rlp_drdy                          (rlp_drdy[@]),
     .rlp_rd_page                       (rlp_rd_page[@"(- (* (+ @ 1) 3) 1)":@"(* @ 3)"]),
 
     .rlpd_srdy                         (rlpd_srdy[@]),
     .rlpd_drdy                         (rlpd_drdy[@]),
     .rlpd_data                         (rlpd_data[lpdsz-1:0]),
 
     .lprt_srdy                         (lprt_srdy[@]),
     .lprt_drdy                         (lprt_drdy[@]),
     .lprt_page_list                    (lprt_page_list[@"(- (* (+ @ 1) 3) 1)":@"(* @ 3)"]),
  );
 */
  llwrport #(/*AUTOINSTPARAM*/
             // Parameters
             .lpsz                      (lpsz),
             .lpdsz                     (lpdsz),
             .sinks                     (sinks)) wport0
    (/*AUTOINST*/
     // Outputs
     .op_drdy                           (op_drdy0),              // Templated
     .rlp_srdy                          (rlp_srdy[0]),           // Templated
     .rlp_rd_page                       (rlp_rd_page[2:0]),      // Templated
     .rlpd_drdy                         (rlpd_drdy[0]),          // Templated
     .lprt_srdy                         (lprt_srdy[0]),          // Templated
     .lprt_page_list                    (lprt_page_list[2:0]),   // Templated
     // Inputs
     .clk                               (clk),
     .reset                             (reset),
     .op_srdy                           (op_srdy0),              // Templated
     .op_page                           (op_page0[(lpsz)-1:0]),  // Templated
     .rlp_drdy                          (rlp_drdy[0]),           // Templated
     .rlpd_srdy                         (rlpd_srdy[0]),          // Templated
     .rlpd_data                         (rlpd_data[lpdsz-1:0]),  // Templated
     .lprt_drdy                         (lprt_drdy[0]));          // Templated

  llwrport #(/*AUTOINSTPARAM*/
             // Parameters
             .lpsz                      (lpsz),
             .lpdsz                     (lpdsz),
             .sinks                     (sinks)) wport1
    (/*AUTOINST*/
     // Outputs
     .op_drdy                           (op_drdy1),              // Templated
     .rlp_srdy                          (rlp_srdy[1]),           // Templated
     .rlp_rd_page                       (rlp_rd_page[5:3]),      // Templated
     .rlpd_drdy                         (rlpd_drdy[1]),          // Templated
     .lprt_srdy                         (lprt_srdy[1]),          // Templated
     .lprt_page_list                    (lprt_page_list[5:3]),   // Templated
     // Inputs
     .clk                               (clk),
     .reset                             (reset),
     .op_srdy                           (op_srdy1),              // Templated
     .op_page                           (op_page1[(lpsz)-1:0]),  // Templated
     .rlp_drdy                          (rlp_drdy[1]),           // Templated
     .rlpd_srdy                         (rlpd_srdy[1]),          // Templated
     .rlpd_data                         (rlpd_data[lpdsz-1:0]),  // Templated
     .lprt_drdy                         (lprt_drdy[1]));          // Templated

  llwrport #(/*AUTOINSTPARAM*/
             // Parameters
             .lpsz                      (lpsz),
             .lpdsz                     (lpdsz),
             .sinks                     (sinks)) wport2
    (/*AUTOINST*/
     // Outputs
     .op_drdy                           (op_drdy2),              // Templated
     .rlp_srdy                          (rlp_srdy[2]),           // Templated
     .rlp_rd_page                       (rlp_rd_page[8:6]),      // Templated
     .rlpd_drdy                         (rlpd_drdy[2]),          // Templated
     .lprt_srdy                         (lprt_srdy[2]),          // Templated
     .lprt_page_list                    (lprt_page_list[8:6]),   // Templated
     // Inputs
     .clk                               (clk),
     .reset                             (reset),
     .op_srdy                           (op_srdy2),              // Templated
     .op_page                           (op_page2[(lpsz)-1:0]),  // Templated
     .rlp_drdy                          (rlp_drdy[2]),           // Templated
     .rlpd_srdy                         (rlpd_srdy[2]),          // Templated
     .rlpd_data                         (rlpd_data[lpdsz-1:0]),  // Templated
     .lprt_drdy                         (lprt_drdy[2]));          // Templated

  llwrport #(/*AUTOINSTPARAM*/
             // Parameters
             .lpsz                      (lpsz),
             .lpdsz                     (lpdsz),
             .sinks                     (sinks)) wport3
    (/*AUTOINST*/
     // Outputs
     .op_drdy                           (op_drdy3),              // Templated
     .rlp_srdy                          (rlp_srdy[3]),           // Templated
     .rlp_rd_page                       (rlp_rd_page[11:9]),     // Templated
     .rlpd_drdy                         (rlpd_drdy[3]),          // Templated
     .lprt_srdy                         (lprt_srdy[3]),          // Templated
     .lprt_page_list                    (lprt_page_list[11:9]),  // Templated
     // Inputs
     .clk                               (clk),
     .reset                             (reset),
     .op_srdy                           (op_srdy3),              // Templated
     .op_page                           (op_page3[(lpsz)-1:0]),  // Templated
     .rlp_drdy                          (rlp_drdy[3]),           // Templated
     .rlpd_srdy                         (rlpd_srdy[3]),          // Templated
     .rlpd_data                         (rlpd_data[lpdsz-1:0]),  // Templated
     .lprt_drdy                         (lprt_drdy[3]));          // Templated

/* -----\/----- EXCLUDED -----\/-----
  llstub #(/-*AUTOINSTPARAM*-/
           // Parameters
           .lpsz                        (lpsz),
           .sinks                       (sinks),
           .sources                     (sources)) ls
    (/-*AUTOINST*-/
     // Outputs
     .pgreq                             (pgreq[(sources)-1:0]),
     .lprq_drdy                         (lprq_drdy[(sources)-1:0]),
     .lprt_srdy                         (lprt_srdy[(sinks)-1:0]),
     .lprt_page_list                    (lprt_page_list[(sinks)*(lpsz)-1:0]),
     // Inputs
     .clk                               (clk),
     .reset                             (reset),
     .pgack                             (pgack[(sources)-1:0]),
     .lprq_srdy                         (lprq_srdy[(sources)-1:0]),
     .lprq_page                         (lprq_page[(lpsz)-1:0]),
     .lprt_drdy                         (lprt_drdy[(sinks)-1:0]));
 -----/\----- EXCLUDED -----/\----- */

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
              head = lm.pglist_mem.array[head];
            end // while (head != tail)
          instant_walk_free = free_count;
        end
    end
  endfunction

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
          head = lm.pglist_mem.array[head];
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
