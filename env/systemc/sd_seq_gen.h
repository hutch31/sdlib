#ifndef SD_SEQ_GEN_H
#define SD_SEQ_GEN_H

#include <stdint.h>
#include "systemc.h"

SC_MODULE(sd_seq_gen) {
 private:
  int seqnum;
  bool prev_srdy;
 public:
  sc_in<bool> clk;
  sc_in<bool> reset;
  sc_out<bool>    srdy;
  sc_in<bool>     drdy;
  sc_out<uint32_t>data;

  void event();

  SC_CTOR(sd_seq_gen) {
    SC_METHOD(event);
    sensitive << clk.pos();
    seqnum = 0;
  }
};

#endif

