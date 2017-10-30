from migen.fhdl.std import *
from migen.fhdl.verilog import convert
import math
import sdlib
from sdlib import clog2
import subprocess
import unittest
import os


class sender(Module):
    def __init__(self, width=8, targets=8):
        tcount = [Signal(width//2) for t in range(targets)]
        addr = Signal(clog2(targets))
        src_id = Signal(clog2(targets))
        i_src_id = Signal(width//2)
        srdy = Signal()
        drdy = Signal()
        data = Signal(width)
        out_seq = Signal(width//2)
        active = Signal(targets)
        valid_addr = Signal()

        self.comb += i_src_id.eq(src_id)
        self.comb += out_seq.eq(Array(tcount)[addr])
        self.comb += valid_addr.eq(Array(active)[addr])
        self.sync += If((srdy & drdy) | ~valid_addr, addr.eq(addr + 1))
        self.sync += If(srdy & drdy, Case(addr, {t : tcount[t].eq(tcount[t] + 1) for t in range(targets)}))
        self.comb += data.eq(Cat(out_seq, i_src_id))
        self.sync += If(srdy & drdy, srdy.eq(0)).Else(srdy.eq(srdy | valid_addr))

        self.io = set([srdy, drdy, addr, data, src_id, active])

class receiver(Module):
    def __init__(self, width=8, sources=4):
        scount = [Signal(width//2) for t in range(sources)]
        addr = Signal(clog2(sources))
        targ_id = Signal(clog2(sources))
        srdy = Signal()
        drdy = Signal()
        data = Signal(width)
        seq_error = Signal()
        targ_error = Signal()
        cur_src = Signal(width//2)

        self.io = set([srdy, drdy, addr, data, targ_id, seq_error, targ_error])

        self.comb += Case(data[width//2:], { t : cur_src.eq(scount[t]) for t in range(sources)})
        self.comb += If(srdy & drdy & (cur_src != data[:width//2]), seq_error.eq(1)).Else(seq_error.eq(0))
        self.comb += targ_error.eq(srdy & (addr != targ_id))
        self.sync += If(srdy & drdy & (cur_src == data[:width//2]),
                        Case(data[width//2:], { t : scount[t].eq(scount[t] + 1) for t in range(sources)}))
        self.sync += drdy.eq(1)


class harness(Module):
    def __init__(self, ports=16, width=8):
        senders = [Instance(of="sender{}".format(ports)) for p in range(ports)]
        receivers = [Instance(of="receiver{}".format(ports)) for p in range(ports)]
        bfly = Instance(of="butterfly{}".format(ports))
        abits = clog2(ports)

        clk = Signal()
        rst = Signal()

        targ_error = Signal(ports)
        seq_error = Signal(ports)
        active = Signal(ports)
        c_srdy = Signal(ports)
        c_drdy = Signal(ports)
        c_data = [Signal(width) for p in range(ports)]
        c_addr = [Signal(abits) for p in range(ports)]
        src_id = [Signal(abits) for p in range(ports)]

        p_srdy = Signal(ports)
        p_drdy = Signal(ports)
        p_data = [Signal(width) for p in range(ports)]
        p_addr = [Signal(abits) for p in range(ports)]

        #self.comb += active.eq((1 << (ports+1)) - 1)
        bfly.items.append(Instance.Input("sys_clk", clk))
        bfly.items.append(Instance.Input("sys_rst", rst))

        for s in range(ports):
            senders[s].items.append(Instance.Input("sys_clk", clk))
            senders[s].items.append(Instance.Input("sys_rst", rst))
            senders[s].items.append(Instance.Output("srdy", c_srdy[s]))
            senders[s].items.append(Instance.Input("drdy", c_drdy[s]))
            senders[s].items.append(Instance.Output("addr", c_addr[s]))
            senders[s].items.append(Instance.Output("data", c_data[s]))
            senders[s].items.append(Instance.Input("src_id", src_id[s]))
            senders[s].items.append(Instance.Input("active", active))
            self.comb += src_id[s].eq(s)

            receivers[s].items.append(Instance.Input("sys_clk", clk))
            receivers[s].items.append(Instance.Input("sys_rst", rst))
            receivers[s].items.append(Instance.Input("srdy", p_srdy[s]))
            receivers[s].items.append(Instance.Output("drdy", p_drdy[s]))
            receivers[s].items.append(Instance.Input("addr", p_addr[s]))
            receivers[s].items.append(Instance.Input("data", p_data[s]))
            receivers[s].items.append(Instance.Input("targ_id", src_id[s]))
            receivers[s].items.append(Instance.Output("targ_error", targ_error[s]))
            receivers[s].items.append(Instance.Output("seq_error", seq_error[s]))

            bfly.items.append(Instance.Input("c{}_srdy".format(s), c_srdy[s]))
            bfly.items.append(Instance.Output("c{}_drdy".format(s), c_drdy[s]))
            bfly.items.append(Instance.Input("c{}_addr".format(s), c_addr[s]))
            bfly.items.append(Instance.Input("c{}_data".format(s), c_data[s]))

            bfly.items.append(Instance.Output("p{}_srdy".format(s), p_srdy[s]))
            bfly.items.append(Instance.Input("p{}_drdy".format(s), p_drdy[s]))
            bfly.items.append(Instance.Output("p{}_addr".format(s), p_addr[s]))
            bfly.items.append(Instance.Output("p{}_data".format(s), p_data[s]))
            
        self.specials += senders, receivers, bfly
        self.io = set([clk, rst, active, targ_error, seq_error])

class harness_tb(Module):
    def __init__(self, ports=16):
        clk = Signal()
        rst = Signal()

        targ_error = Signal(ports)
        seq_error = Signal(ports)
        active = Signal(ports)

        harness_control = Instance(of="harness_control")
        harness_control.items.append(Instance.Parameter("ports", ports))
        harness_control.items.append(Instance.Output("clk", clk))
        harness_control.items.append(Instance.Output("rst", rst))
        harness_control.items.append(Instance.Output("active", active))
        harness_control.items.append(Instance.Input("targ_error", targ_error))
        harness_control.items.append(Instance.Input("seq_error", seq_error))

        h = Instance(of="harness{}".format(ports))
        h.items.append(Instance.Input("clk", clk))
        h.items.append(Instance.Input("rst", rst))
        h.items.append(Instance.Input("active", active))
        h.items.append(Instance.Output("targ_error", targ_error))
        h.items.append(Instance.Output("seq_error", seq_error))

        self.specials += harness_control, h



def create_bench(ports):
    radix = clog2(ports)
    width = radix * 2
    print("Generating butterfly with radix == {}".format(radix))
    bf = sdlib.sd_butterfly(radix=radix, width=width)
    convert(bf, bf.io, name="butterfly{}".format(ports), asic_syntax=True).write("butterfly{}.v".format(ports))
    senders = sender(width=width, targets=ports)
    convert(senders, senders.io, name="sender{}".format(ports), asic_syntax=True).write("sender{}.v".format(ports))
    rcvr = receiver(width=width, sources=ports)
    convert(rcvr, rcvr.io, name="receiver{}".format(ports), asic_syntax=True).write("receiver{}.v".format(ports))
    se = harness(ports=ports, width=width)
    convert(se, se.io, name="harness{}".format(ports), asic_syntax=True).write("harness{}.v".format(ports))
    tb = harness_tb(ports=ports)
    convert(tb, name="harness_tb{}".format(ports)).write("harness_tb{}.v".format(ports))

def run_bench(ports, debug=False):
    # add lint for debug "+lint=TFIPC-L", 
    command = [x.format(ports) for x in ["grid_vcs.py", "-debug_access", "-R", "harness_tb{}.v", "harness_control.v", "harness{}.v", "sender{}.v", "receiver{}.v", "butterfly{}.v"]]
    if debug:
        subprocess.check_call(command)
        return False
    else:
        results = subprocess.check_output(command, universal_newlines=True)

    if results.find("TEST PASS") != -1:
        return True
    else:
        return False

def cleanup(ports):
    for f in [x.format(ports)+".v" for x in ["butterfly{}", "harness{}", "harness_tb{}", "sender{}", "receiver{}"]]:
        os.unlink(f)


class test_radix(unittest.TestCase):
    def test_4(self):
        create_bench(4)
        self.assertTrue(run_bench(4))
        cleanup(4)

    def test_8(self):
        create_bench(8)
        self.assertTrue(run_bench(8))
        cleanup(8)

    def test_16(self):
        create_bench(16)
        self.assertTrue(run_bench(16))
        cleanup(16)

    def test_32(self):
        create_bench(32)
        self.assertTrue(run_bench(32))
        cleanup(32)

if __name__ == "__main__":
    unittest.main()

    #create_bench(4)
    #run_bench(4, debug=True)


                     

