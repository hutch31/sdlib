#!/usr/bin/python

import vlaunch

def run_sim(rate):
    print "Starting simulation with rate=",rate
    vlaunch.setFinishTime (5000);

    for did in range(0,4):
        for x in range(0,32):
            data = x | did << 6;
            vlaunch.addDpiDriverData (did, data)

    vlaunch.setTargetRate (0, rate * 0.2)
    vlaunch.setTargetRate (1, rate * 0.4)
    vlaunch.setTargetRate (2, rate * 0.6)
    vlaunch.setTargetRate (3, rate * 0.8)

    vlaunch.launch()

    print "Sim complete, checking results"

    for mon in range(0,4):
        val = 0
        dout = vlaunch.getDpiDriverData (mon+4)
        while dout != -1:
            #print "Mon %d=%x" % (mon,dout & 0x3F)
            if (dout & 0x3F) != val:
                print "ERROR: ",dout,val
            else:
                val += 1
            dout = vlaunch.getDpiDriverData (mon+4)

for i in range(1,20):
    run_sim (0.05 * i)

