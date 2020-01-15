#!/usr/bin/env python3

import argparse
import os
import sys

parser = argparse.ArgumentParser(description='Run an sdlib test and check results')
parser.add_argument('--test', help="Module name for test")

args = parser.parse_args()

os.chdir('env/verilog/'+args.test)
os.system("iverilog -g2012 -f {}.vf".format(args.test))
os.system("./a.out > test.log")

passed = False
with open("test.log", "r") as fh:
    for fd in fh:
        if fd.find("TEST PASSED") != -1:
            passed = True

if passed:
    print("{} passed".format(args.test))
    sys.exit(0)
else:
    print("{} failed".format(args.test))
    sys.exit(1)
