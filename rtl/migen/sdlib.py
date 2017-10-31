#----------------------------------------------------------------------
# Srdy/Drdy Library Components
#
# Library to create a variety of srdy/drdy interface blocks based on
# the Migen HDL generation library.
#
# Naming convention: c = consumer, p = producer
#----------------------------------------------------------------------
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
#----------------------------------------------------------------------



from migen.fhdl.std import *
from migen.fhdl.verilog import convert


def clog2(x):
    '''Match behavior of verilog $clog2() function, which determines the number of bits required for a given value
    '''
    return (x-1).bit_length()

class sd_interface:
    '''Storage class for containing an interface with bi-directional flow control
    '''
    def __init__(self, name=None, width=8):
        self.name = name

        self.srdy = Signal()
        self.drdy = Signal()
        self.data = Signal(width)
        if name:
            self.srdy.name_override = name+"_srdy"
            self.drdy.name_override = name+"_drdy"
            self.data.name_override = name+"_data"
        self.signals = [self.srdy, self.drdy, self.data]

    # Connect up output interface to target(input) interface
    def connect(self, target, module):
        module.comb += target.signals[0].eq(self.signals[0])
        module.comb += self.signals[1].eq(target.signals[1])
        module.comb += target.signals[2].eq(self.signals[2])

class sd_addr_interface(sd_interface):
    '''Extends the base sd_interface class for address plus data interfaces, such as used by crossbar network
    '''
    def __init__(self, name=None, asz=3, width=8):
        super().__init__(name, width)
        self.addr = Signal(asz)
        self.signals.append(self.addr)
        if name:
            self.addr.name_override=name+"_addr"

    # Connect up output interface to target(input) interface
    def connect(self, target, module):
        super().connect(target, module)
        module.comb += target.signals[3].eq(self.signals[3])


class sd_input(Module):
    def __init__(self, width=8, name=None):
        if name:
            name_p = name+"_p"
            name_c = name+"_c"
        else:
            name_p = "p"
            name_c = "c"
        self.p = sd_interface(name_p, width)
        self.c = sd_interface(name_c, width)

        occupied = Signal()
        hold = Signal(width)
        load = Signal()

        self.comb += load.eq(self.c.srdy & self.c.drdy & (~self.p.drdy | (occupied & self.p.drdy)))
        self.comb += If(occupied,self.p.data.eq(hold)).Else(self.p.data.eq(self.c.data))
        self.comb += self.p.srdy.eq((self.c.srdy & self.c.drdy) | occupied)

        self.sync += If(load, occupied.eq(1)).Elif(occupied & self.p.drdy, occupied.eq(0))
        self.sync += If(load, hold.eq(self.c.data))
        self.sync += self.c.drdy.eq((~occupied & ~load) | (occupied & self.p.drdy & ~load))

class sd_output(Module):
    def __init__(self, width=8, name=None):
        if name:
            name_p = name+"_p"
            name_c = name+"_c"
        else:
            name_p = "p"
            name_c = "c"
        self.p = sd_interface(name_p, width)
        self.c = sd_interface(name_c, width)

        self.comb += self.c.drdy.eq(self.p.drdy | ~self.p.srdy)
        self.sync += self.p.srdy.eq((self.c.srdy & self.c.drdy) | (self.p.srdy & ~self.p.drdy))
        self.sync += If(self.c.srdy & self.c.drdy, self.p.data.eq(self.c.data))


class sd_fifo_c(Module):
    def __init__(self, width=8, depth=8):
        self.p = sd_interface("p", width)
        self.c = sd_interface("c", width)
        ptr_sz = clog2(depth)
        usage_sz = clog2(depth+1)

        usage = Signal(usage_sz)
        full = Signal()
        wr_en = Signal()
        rd_en = Signal()
        buffer = [Signal(width) for x in range(depth)]

        wrptr_p1 = Signal(ptr_sz)
        rdptr_p1 = Signal(ptr_sz)
        wrptr = Signal(ptr_sz)
        rdptr = Signal(ptr_sz)
        self.comb += If(wrptr == (depth - 1), wrptr_p1.eq(0)).Else(wrptr_p1.eq(wrptr + 1))
        self.comb += full.eq(usage == depth)
        self.comb += wr_en.eq(self.c.srdy & ~full)
        self.sync += If(wr_en, wrptr.eq(wrptr_p1))

        self.comb += If(rdptr == (depth - 1), rdptr_p1.eq(0)).Else(rdptr_p1.eq(rdptr + 1))
        self.comb += rd_en.eq(self.p.srdy & self.p.drdy)
        self.sync += If(rd_en, rdptr.eq(rdptr_p1))
        self.comb += self.p.drdy.eq(~full)

        self.sync += self.p.srdy.eq((self.p.srdy & ~self.p.drdy) | (~self.p.srdy & (usage != 0)) | (self.p.srdy & self.p.drdy & (usage > 1)))

        self.sync += If(wr_en & ~rd_en, usage.eq(usage + 1)).Elif(rd_en & ~wr_en, usage.eq(usage - 1))

        for w in range(depth):
            self.sync += If(wr_en & (wrptr == w), buffer[w].eq(self.c.data))

        self.comb += Case(rdptr, {w : self.p.data.eq(buffer[w]) for w in range(depth)})


class sd_switch_elem(Module):
    def __init__(self, name="sw", abit=0, asz=3, width=8):
        self.in_if = [sd_addr_interface(name+"_c0", asz, width), sd_addr_interface(name+"_c1", asz, width)]
        self.out_if = [sd_addr_interface(name+"_p0", asz, width), sd_addr_interface(name+"_p1", asz, width)]

        priority = Signal(name_override=name+"_pri")
        switch = Signal(name_override=name+"_switch")
        sdin = [sd_input(asz+width, name=name+"_i0"),sd_input(asz+width, name=name+"_i1")]
        sdout = [sd_output(asz+width, name=name+"_o0"), sd_output(asz+width, name=name+"_o1")]

        a = [Signal(name_override=name+"_a0"), Signal(name_override=name+"_a1")]

        self.submodules += sdin[0], sdin[1], sdout[0], sdout[1]
        for m in range(2):
            self.comb += sdin[m].c.srdy.eq(self.in_if[m].srdy)
            self.comb += self.in_if[m].drdy.eq(sdin[m].c.drdy)
            self.comb += sdin[m].c.data.eq(Cat(self.in_if[m].addr, self.in_if[m].data))

            self.comb += self.out_if[m].srdy.eq(sdout[m].p.srdy)
            self.comb += sdout[m].p.drdy.eq(self.out_if[m].drdy)
            self.comb += self.out_if[m].addr.eq(sdout[m].p.data[:asz])
            self.comb += self.out_if[m].data.eq(sdout[m].p.data[asz:])

            self.comb += a[m].eq(sdin[m].p.data[abit])

        self.comb += If(sdin[0].c.srdy & sdin[1].c.srdy & ~priority, switch.eq(a[0])).\
            Elif(sdin[0].c.srdy & sdin[1].c.srdy & priority, switch.eq(~a[1])).\
            Elif(sdin[0].c.srdy & ~sdin[1].c.srdy, switch.eq(a[0])).\
            Elif(~sdin[0].c.srdy & sdin[1].c.srdy, switch.eq(~a[1])).Else(switch.eq(a[0]))

        # If selection is to switch, then connect sdin 0 to sdout 1 and vice versa
        # If selection is not to switch, then connect straight through
        self.comb += If(switch, sdout[0].c.srdy.eq(sdin[1].p.srdy & ~a[1]),
                        sdout[0].c.data.eq(sdin[1].p.data),
                        sdin[1].p.drdy.eq(sdout[0].c.drdy & ~a[1]),
                        sdout[1].c.srdy.eq(sdin[0].p.srdy & a[0]),
                        sdout[1].c.data.eq(sdin[0].p.data),
                        sdin[0].p.drdy.eq(sdout[1].c.drdy & a[0])).\
            Else(sdout[0].c.srdy.eq(sdin[0].p.srdy & ~a[0]),
                        sdout[0].c.data.eq(sdin[0].p.data),
                        sdin[0].p.drdy.eq(sdout[0].c.drdy & ~a[0]),
                        sdout[1].c.srdy.eq(sdin[1].p.srdy & a[1]),
                        sdout[1].c.data.eq(sdin[1].p.data),
                        sdin[1].p.drdy.eq(sdout[1].c.drdy & a[1]))

        # Swap priority whenever current high-priority input gets a grant
        self.sync += If(priority & sdin[1].p.srdy & sdin[1].p.drdy, priority.eq(0)).\
            Elif(~priority & sdin[0].p.srdy & sdin[0].p.drdy, priority.eq(1))


class sd_butterfly(Module):
    def __init__(self, radix=3, width=8):
        self.ports = 2 ** radix
        nodes = self.ports // 2
        self.in_if = [sd_addr_interface("c{}".format(p), asz=radix, width=width) for p in range(self.ports)]
        self.out_if = [sd_addr_interface("p{}".format(p), asz=radix, width=width) for p in range(self.ports)]
        self.io = set()
        for i in self.in_if+self.out_if:
            self.io.update([i.srdy, i.drdy, i.addr, i.data])

        switches = []
        for r in range(radix):
            column = [sd_switch_elem(name="r{}n{}".format(r,n), abit=r, asz=radix, width=width) for n in range(nodes)]
            for c in column:
                self.submodules += c
            switches.append(column)

        # Stitch primary inputs/outputs to first level switches
        for inum in range(self.ports):
            nnum = inum // 2
            pnum = inum % 2
            #onum = inum
            onum = (inum >> 1) | ((inum & 1) << (radix-1))
            self.comb += switches[0][nnum].in_if[pnum].srdy.eq(self.in_if[inum].srdy)
            self.comb += switches[0][nnum].in_if[pnum].addr.eq(self.in_if[inum].addr)
            self.comb += switches[0][nnum].in_if[pnum].data.eq(self.in_if[inum].data)
            self.comb += self.in_if[inum].drdy.eq(switches[0][nnum].in_if[pnum].drdy)

            self.comb += switches[-1][nnum].out_if[pnum].drdy.eq(self.out_if[onum].drdy)
            self.comb += self.out_if[onum].srdy.eq(switches[-1][nnum].out_if[pnum].srdy)
            self.comb += self.out_if[onum].addr.eq(switches[-1][nnum].out_if[pnum].addr)
            self.comb += self.out_if[onum].data.eq(switches[-1][nnum].out_if[pnum].data)

        # Connect internal rows
        for c in range(0, radix-1):
            for node in range(nodes):
                connections = [node, node ^ (1 << c)]
                if connections[0] > connections[1]:
                    dport = 1
                else:
                    dport = 0
                connections = sorted(connections)
                #print("Col{} Node{}".format(c, node), connections)

                for p in range(2):
                    self.comb += switches[c][node].out_if[p].drdy.eq(switches[c+1][connections[p]].in_if[dport].drdy)
                    self.comb += switches[c+1][connections[p]].in_if[dport].srdy.eq(switches[c][node].out_if[p].srdy)
                    self.comb += switches[c+1][connections[p]].in_if[dport].addr.eq(switches[c][node].out_if[p].addr)
                    self.comb += switches[c + 1][connections[p]].in_if[dport].data.eq(switches[c][node].out_if[p].data)


