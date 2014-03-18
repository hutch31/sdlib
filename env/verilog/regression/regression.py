#!/usr/bin/python3

import os,subprocess

modules = ["fifo_c","fifo_b","fifo_s","rrmux"]

def run_module (module):
    cwd = os.getcwd()
    os.chdir ("../"+module)
    subprocess.check_call (["iverilog","-g2012","-f",module+".vf",'-o',module])
    output = str(subprocess.check_output ("./"+module))
    os.chdir (cwd)
    if output.find ("TEST PASSED") != -1:
        return True
    else: return False

results = {}
for m in modules:
    results[m] = run_module (m)

print (repr(results))

