#!/usr/bin/env python

# ----------------------------------------------------------------------
# Butterfly network generator script
#
# Creates a butterfly network of P ports using the sd_bfnode module.
# P must be a power of 2 for both inputs and outputs.
#
# By default creates a network from "narrow" to "wide", so the left
# side of the network has local connetivity and the right side has
# global connectivity.  The reverse option creates a network with
# wide to narrow instead.
# ----------------------------------------------------------------------
# Author: Guy Hutchison
#
# This is free and unencumbered software released into the public domain.
#
# Anyone is free to copy, modify, publish, use, compile, sell, or
# distribute this software, either in source code form or as a compiled
# binary, for any purpose, commercial or non-commercial, and by any
# means.
#
# In jurisdictions that recognize copyright laws, the author or authors
# of this software dedicate any and all copyright interest in the
# software to the public domain. We make this dedication for the benefit
# of the public at large and to the detriment of our heirs and
# successors. We intend this dedication to be an overt act of
# relinquishment in perpetuity of all present and future rights to this
# software under copyright law.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
# OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
# ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.
#
# For more information, please refer to <http://unlicense.org/>
# ----------------------------------------------------------------------

import math
import argparse


def nodeIndex(t):
    '''Generates the connectivity from each node to the nodes in the next column
    t is a tuple of (m, n) where m is module number in a column and n is the column number
    '''
    (m, n) = t
    if (m & (1 << n)):
        x = (m - (1 << n))
        y = m
    else:
        x = m
        y = m+(1 << n)
    return (x, y)


def generateButterfly(ports, modname="bfnetwork", reverse=False):
    '''Creates a butterfly network for sd_bfnode, returns resulting Verilog
    code as a string.'''
    output = ''

    npc = ports // 2
    nrow = int(math.log(ports) / math.log(2))

    output += "module {} #(parameter width=32, parameter abits=3) (input clk, \n".format(modname)
    output += "    input  [{0}:0] c_srdy,\n    output [{0}:0] c_drdy,\n".format(ports - 1)
    output += "    output [{0}:0] p_srdy,\n    input  [{0}:0] p_drdy,\n".format(ports - 1)
    output += "    input  [{0}-1:0][abits-1:0] c_addr,\n    output [{0}-1:0][abits-1:0] p_addr,\n".format(ports)
    output += "    input  [{0}-1:0][width-1:0] c_data,\n    output [{0}-1:0][width-1:0] p_data,\n".format(ports)
    output += "    input reset);\n"

    # declare wires
    for nr in range(nrow-1):
        output += '''
  wire [{1}:0] r{0}_srdy;
  wire [{1}:0] r{0}_drdy;
  wire [{1}:0][abits-1:0] r{0}_addr;
  wire [{1}:0][width-1:0] r{0}_data;
'''.format(nr, ports-1)
        #for p in range(ports):
        #    output += "  wire r{0}_p{1}_srdy, r{0}_p{1}_drdy;\n  wire [width-1:0] r{0}_p{1}_data;\n".format(nr, p)

    # declare nodes
    asel = list(range(1, nrow))
    if reverse:
        asel.reverse()
    asel.append(0)
    for nr in range(nrow):
        for node in range(npc):

            output += "  sd_bfnode #(.width(width), .asel({2})) node_r{0}_n{1}".format(nr, node, asel[nr])
            output += "    (.clk (clk), \n"
            if nr == 0:
                output += "    .c_srdy_a (c_srdy[{0}]), .c_drdy_a(c_drdy[{0}]), .c_addr_a(c_addr[{0}]), .c_data_a(c_data[{0}]),\n".format(node*2)
                output += "    .c_srdy_b (c_srdy[{0}]), .c_drdy_b(c_drdy[{0}]), .c_addr_b(c_addr[{0}]), .c_data_b(c_data[{0}]),\n".format(node*2+1)
            else:
                output += "    .c_srdy_a (r{0}_srdy[{1}]), .c_drdy_a (r{0}_drdy[{1}]), .c_addr_a(r{0}_addr[{1}]), .c_data_a (r{0}_data[{1}]),\n".format(nr-1, node*2)
                output += "    .c_srdy_b (r{0}_srdy[{1}]), .c_drdy_b (r{0}_drdy[{1}]), .c_addr_b(r{0}_addr[{1}]), .c_data_b (r{0}_data[{1}]),\n".format(nr-1, node*2+1)

            if nr != (nrow-1):
                if reverse:
                    nirow = nrow-nr-2
                else:
                    nirow = nr
                da, db = nodeIndex((node, nirow))
                da = da * 2 + ((node & (1 << nr)) >> nr)
                db = db * 2 + ((node & (1 << nr)) >> nr)
                print("Debug: nirow={} node={} da={} db={}".format(nirow, node, da, db))
                output += "    .p_srdy_a (r{0}_srdy[{1}]), .p_drdy_a (r{0}_drdy[{1}]), .p_addr_a(r{0}_addr[{1}]), .p_data_a (r{0}_data[{1}]),\n".format(nr, da)
                output += "    .p_srdy_b (r{0}_srdy[{1}]), .p_drdy_b (r{0}_drdy[{1}]), .p_addr_b(r{0}_addr[{1}]), .p_data_b (r{0}_data[{1}]),\n".format(nr, db)
            else:
                output += "    .p_srdy_a (p_srdy[{0}]), .p_drdy_a (p_drdy[{0}]), .p_addr_a (p_addr[{0}]), .p_data_a (p_data[{0}]),\n".format(node * 2)
                output += "    .p_srdy_b (p_srdy[{0}]), .p_drdy_b (p_drdy[{0}]), .p_addr_b (p_addr[{0}]), .p_data_b (p_data[{0}]),\n".format(node * 2 + 1)
            output += "     .reset (reset));\n"

    output += "endmodule\n"
    return output


def main():
    parser = argparse.ArgumentParser(description='Create Verilog butterfly network')
    parser.add_argument('-p', '--ports', type=int, default=4,
                        help="Number of ports on network, must be power of 2")
    parser.add_argument('-m', '--modname', type=str, default="sd_bf4",
                        help="Module name of generated file")
    parser.add_argument('-r', '--reverse', action='store_true',
                        help="Generate butterfly network in reverse order")
    parser.add_argument('-f', '--filename', type=str, default="sd_bf4.v",
                        help="Output filename")

    args = parser.parse_args()

    with open(args.filename, "w") as fh:
        fh.write(generateButterfly(args.ports, modname=args.modname, reverse=args.reverse))

main()
