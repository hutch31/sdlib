#!/usr/bin/python

import os

files = ['bench_rrmux.v', 'sd_seq_check.v', 'sd_seq_gen.v', '-y ../../../rtl/verilog/forks']

os.system ("vcs +v2k -full64 +libext+.v -R -I " + " ".join(files))
