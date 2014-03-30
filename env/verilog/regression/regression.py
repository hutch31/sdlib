#!/usr/bin/python3

import os,subprocess


def run_module (module):
    cwd = os.getcwd()
    os.chdir ("../"+module)
    subprocess.check_call (["iverilog","-g2012","-f",module+".vf",'-o',module])
    output = str(subprocess.check_output ("./"+module))
    os.chdir (cwd)
    if output.find ("TEST PASSED") != -1:
        return True
    else: return False

def run_regression ():
    results = {}
    print ("%-10s %6s" % ("Test Name", "Result"))
    for m in modules:
        results[m] = run_module (m)
        if results[m]: status = "PASS"
        else: status = "FAIL"
        print ("%-10s %6s" % ( m, status))

modules = ["fifo_c","fifo_b","fifo_s","rrmux","vcif","mux_demux"]
run_regression()

