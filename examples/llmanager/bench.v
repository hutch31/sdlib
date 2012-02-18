`timescale 1ns/1ns

module bench;

  localparam sources = 4;
  localparam sinks = 4;
  localparam lpsz = 8;

  reg   clk;
  reg   reset;

  /*AUTOWIRE*/
  // Beginning of automatic wires (for undeclared instantiated-module outputs)
  wire [sources-1:0]    lprq_drdy;              // From ls of llstub.v
  wire [lpsz-1:0]       lprq_page;              // From lm of llmanager.v
  wire [sources-1:0]    lprq_srdy;              // From lm of llmanager.v
  wire [sinks-1:0]      lprt_drdy;              // From lm of llmanager.v
  wire [sinks*lpsz-1:0] lprt_page_list;         // From ls of llstub.v
  wire [sinks-1:0]      lprt_srdy;              // From ls of llstub.v
  wire [sources-1:0]    pgack;                  // From lm of llmanager.v
  wire [sources-1:0]    pgreq;                  // From ls of llstub.v
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
      $finish;
    end

  always clk = #5 ~clk;

  llmanager lm
    (/*AUTOINST*/
     // Outputs
     .pgack                             (pgack[sources-1:0]),
     .lprq_srdy                         (lprq_srdy[sources-1:0]),
     .lprq_page                         (lprq_page[lpsz-1:0]),
     .lprt_drdy                         (lprt_drdy[sinks-1:0]),
     // Inputs
     .clk                               (clk),
     .reset                             (reset),
     .pgreq                             (pgreq[sources-1:0]),
     .lprq_drdy                         (lprq_drdy[sources-1:0]),
     .lprt_srdy                         (lprt_srdy[sinks-1:0]),
     .lprt_page_list                    (lprt_page_list[sinks*lpsz-1:0]));

  llstub ls
    (/*AUTOINST*/
     // Outputs
     .pgreq                             (pgreq[sources-1:0]),
     .lprq_drdy                         (lprq_drdy[sources-1:0]),
     .lprt_srdy                         (lprt_srdy[sinks-1:0]),
     .lprt_page_list                    (lprt_page_list[sinks*lpsz-1:0]),
     // Inputs
     .clk                               (clk),
     .pgack                             (pgack[sources-1:0]),
     .lprq_srdy                         (lprq_srdy[sources-1:0]),
     .lprq_page                         (lprq_page[lpsz-1:0]),
     .lprt_drdy                         (lprt_drdy[sinks-1:0]));

endmodule // bench
