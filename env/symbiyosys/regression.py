#!/usr/bin/env python3

import unittest
import subprocess
import os
import string

def find_file(filename):
    for root, dirs, files in os.walk("../../.."):
        for file in files:
            if file == filename:
                filepath = os.path.join(root, file)
                return filepath

def create_template(module, cons="c", prod="p"):
    with open("fbench_template.v", "r") as fh:
        data = fh.read()
    template = string.Template(data)
    result = template.substitute(module=module, prod=prod, cons=cons)
    with open("fbench_"+module+".v", "w") as fh:
        fh.write(result)

    modulepath = find_file(module+".v")

    with open("template.sby", "r") as fh:
        data = fh.read()
    template = string.Template(data)
    result = template.substitute(module=module, modulepath=modulepath)
    with open(module+".sby", "w") as fh:
        fh.write(result)
    
class SymTests(unittest.TestCase):
    def test_common(self):
        os.chdir("common")
        for e, m in enumerate([["sd_input", "c", "ip"], 
                               ["sd_output", "ic", "p"],
                               ["sd_iohalf", "c", "p"]]):
            with self.subTest(i=e):
                create_template(m[0], cons=m[1], prod=m[2])
                output = subprocess.check_output(["sby", "-f", m[0] + ".sby"], universal_newlines=True)
                self.assertTrue(output.find("PASS") != -1)
        os.chdir("..")

    def test_fifo_c(self):
        os.chdir("fifo_c")
        output = subprocess.check_output(["sby", "-f", "fifo_c.sby"], universal_newlines=True)
        self.assertTrue(output.find("PASS") != -1)
        os.chdir("..")

if __name__ == '__main__':
    unittest.main()
