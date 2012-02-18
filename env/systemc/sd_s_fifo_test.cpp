#include "systemc.h"
#include "systemperl.h"
#include "Vmp_bench.h"
#include "SpTraceVcd.h"
#include <unistd.h>

#define NUM_PACKETS 10

extern char *optarg;
extern int optind, opterr, optopt;


int sc_main(int argc, char *argv[])
{
  bool dumping = false;
  int index, packets = NUM_PACKETS;
  char *dumpfile_name;
  char *mem_src_name;
  SpTraceFile *tfp;
  mp_generator *gen[4];
  mp_checker *chk[4];

  while ( (index = getopt(argc, argv, "d:p:")) != -1) {
    if  (index == 'd') {
      dumpfile_name = new char(strlen(optarg)+1);
      strcpy (dumpfile_name, optarg);
      dumping = true;
      printf ("VCD dump enabled to %s\n", dumpfile_name);
    } else if (index == 'p') {
      packets = atoi (optarg);
      assert (packets > 0);
    }
  }
  sc_clock clk("clk125", 8, SC_NS, 0.5);
  sc_signal<bool> reset;
  sc_signal <uint32_t>		data_in[4];
  sc_signal <bool >		irdy_in[4];
  sc_signal <bool >		trdy_out[4];
  sc_signal <uint32_t>		data_out[4];
  //sc_signal <uint32_t>		data_out_1;
  //sc_signal <uint32_t>		data_out_2;
  //sc_signal <uint32_t>		data_out_3;
  sc_signal <bool>		irdy_out[4];
  sc_signal <bool>		trdy_in[4];
  sc_signal <bool> commit_in[4];
  sc_signal <bool> abort_in[4];
  sc_signal <uint32_t>		usage[4];
//   sc_signal <uint32_t>		usage_1;
//   sc_signal <uint32_t>		usage_2;
//   sc_signal <uint32_t>		usage_3;
  
  Vmp_bench mp_bench("mp_bench");
  mp_bench.clk (clk);
  mp_bench.reset (reset);
//   mp_bench.data_in_1 (data_in[1]);
//   mp_bench.data_in_2 (data_in[2]);
//   mp_bench.data_in_3 (data_in[3]);
//   mp_bench.data_out_1 (data_out[1]);
//   mp_bench.data_out_2 (data_out[2]);
//   mp_bench.data_out_3 (data_out[3]);
//   mp_bench.usage_0 (usage[0]);
//   mp_bench.usage_1 (usage[1]);
//   mp_bench.usage_2 (usage[2]);
//   mp_bench.usage_3 (usage[3]);

  mp_bench.irdy_in_0 (irdy_in[0]);
  mp_bench.trdy_in_0 (trdy_in[0]);
  mp_bench.data_in_0 (data_in[0]);
  mp_bench.commit_in_0 (commit_in[0]);
  mp_bench.abort_in_0  (abort_in[0]);

  mp_bench.irdy_in_1 (irdy_in[1]);
  mp_bench.trdy_in_1 (trdy_in[1]);
  mp_bench.data_in_1 (data_in[1]);
  mp_bench.commit_in_1 (commit_in[1]);
  mp_bench.abort_in_1  (abort_in[1]);

  mp_bench.irdy_in_2 (irdy_in[2]);
  mp_bench.trdy_in_2 (trdy_in[2]);
  mp_bench.data_in_2 (data_in[2]);
  mp_bench.commit_in_2 (commit_in[2]);
  mp_bench.abort_in_2  (abort_in[2]);

  mp_bench.irdy_in_3 (irdy_in[3]);
  mp_bench.trdy_in_3 (trdy_in[3]);
  mp_bench.data_in_3 (data_in[3]);
  mp_bench.commit_in_3 (commit_in[3]);
  mp_bench.abort_in_3  (abort_in[3]);

  mp_bench.irdy_out_0 (irdy_out[0]);
  mp_bench.trdy_out_0 (trdy_out[0]);
  mp_bench.data_out_0 (data_out[0]);
  mp_bench.usage_0 (usage[0]);

  mp_bench.irdy_out_1 (irdy_out[1]);
  mp_bench.trdy_out_1 (trdy_out[1]);
  mp_bench.data_out_1 (data_out[1]);
  mp_bench.usage_1 (usage[1]);

  mp_bench.irdy_out_2 (irdy_out[2]);
  mp_bench.trdy_out_2 (trdy_out[2]);
  mp_bench.data_out_2 (data_out[2]);
  mp_bench.usage_2 (usage[2]);

  mp_bench.irdy_out_3 (irdy_out[3]);
  mp_bench.trdy_out_3 (trdy_out[3]);
  mp_bench.data_out_3 (data_out[3]);
  mp_bench.usage_3 (usage[3]);

  reset_drv reset_drv0("reset_drv0");
  reset_drv0.clk (clk);
  reset_drv0.reset (reset);

  char name[16];
  for (int g=0; g<4; g++) {
    sprintf (name, "gen%d", g);
    //gen0(name);
    gen[g] = new mp_generator(name);
    gen[g]->clk (clk);
    gen[g]->reset (reset);
    gen[g]->irdy (irdy_in[g]);
    gen[g]->trdy (trdy_in[g]);
    gen[g]->data (data_in[g]);
    gen[g]->commit (commit_in[g]);
    gen[g]->abort (abort_in[g]);
    gen[g]->max_packets = packets;

    sprintf (name, "chk%d", g);
    chk[g] = new mp_checker(name);
    chk[g]->clk (clk);
    chk[g]->reset (reset);
    chk[g]->irdy (irdy_out[g]);
    chk[g]->trdy (trdy_out[g]);
    chk[g]->data (data_out[g]);
  }

  // Start Verilator traces
  if (dumping) {
    Verilated::traceEverOn(true);
    tfp = new SpTraceFile;
    mp_bench.trace (tfp, 99);
    tfp->open (dumpfile_name);
  }

  reset.write (1);
 
  //sc_start(sc_time(1000000, SC_NS));
  sc_start();

  if (dumping)
    tfp->close();   

  return 0;
}
