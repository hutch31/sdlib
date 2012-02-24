`timescale 1ns/1ns

module bench;

  localparam sources = 4;
  localparam sinks = 4;
  localparam sksz  = 2;
  localparam lpsz = 3;
  localparam pages = 8;

  reg   clk;
  reg   reset;
  integer bfree;

  /*AUTOWIRE*/
  // Beginning of automatic wires (for undeclared instantiated-module outputs)
  wire [(lpsz):0]       free_count;             // From lm of llmanager.v
  wire [(sources)-1:0]  lprq_drdy;              // From ls of llstub.v
  wire [(lpsz)-1:0]     lprq_page;              // From lm of llmanager.v
  wire [(sources)-1:0]  lprq_srdy;              // From lm of llmanager.v
  wire [(sinks)-1:0]    lprt_drdy;              // From lm of llmanager.v
  wire [(sinks)*(lpsz)-1:0] lprt_page_list;     // From ls of llstub.v
  wire [(sinks)-1:0]    lprt_srdy;              // From ls of llstub.v
  wire [(sources)-1:0]  pgack;                  // From lm of llmanager.v
  wire [(sources)-1:0]  pgreq;                  // From ls of llstub.v
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

  llmanager #(
              // Parameters
              .lpsz                     (lpsz),
              .pages                    (pages),
              .sources                  (sources),
              .sinks                    (sinks),
              .sksz                     (sksz)) lm
    (/*AUTOINST*/
     // Outputs
     .pgack                             (pgack[(sources)-1:0]),
     .lprq_srdy                         (lprq_srdy[(sources)-1:0]),
     .lprq_page                         (lprq_page[(lpsz)-1:0]),
     .lprt_drdy                         (lprt_drdy[(sinks)-1:0]),
     .free_count                        (free_count[(lpsz):0]),
     // Inputs
     .clk                               (clk),
     .reset                             (reset),
     .pgreq                             (pgreq[(sources)-1:0]),
     .lprq_drdy                         (lprq_drdy[(sources)-1:0]),
     .lprt_srdy                         (lprt_srdy[(sinks)-1:0]),
     .lprt_page_list                    (lprt_page_list[(sinks)*(lpsz)-1:0]));

  llstub #(/*AUTOINSTPARAM*/
           // Parameters
           .lpsz                        (lpsz),
           .sinks                       (sinks),
           .sources                     (sources)) ls
    (/*AUTOINST*/
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

      $display ("Free list starts at %d", head);
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
