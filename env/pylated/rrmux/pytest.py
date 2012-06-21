#!/usr/bin/python

import vlaunch

vlaunch.setFinishTime (5000);

for x in range(0,100):
    vlaunch.addDpiDriverData (0, x)

vlaunch.launch()

