#include "sd_seq_gen.h"

void sd_seq_gen::event() {
  if (reset) return;

  prev_srdy = srdy;
  if (seqnum == 0)
    srdy = 1;

  if (srdy && drdy) {
    data = seqnum++;
  }
}
