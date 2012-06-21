#!/usr/bin/python

import vlaunch

vlaunch.setFinishTime (5000);

for did in range(0,3):
    for x in range(0,32):
        data = x | did << 6;
        vlaunch.addDpiDriverData (did, data)

vlaunch.setTargetRate (0, 0.1)
vlaunch.setTargetRate (1, 0.3)
vlaunch.setTargetRate (2, 0.8)
vlaunch.setTargetRate (3, 0.8)

vlaunch.launch()

