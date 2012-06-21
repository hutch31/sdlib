#include "Vbench_rrmux.h"
#include "verilated.h"

// includes for DPI call
#include "svdpi.h"
#include "Vbench_rrmux__Dpi.h"
#include <queue>

#define MAX_DRV_ID 64

static int finishTime = 1000;
queue<int> *driverQ[MAX_DRV_ID];

void tbInit () {
  for (int i=0; i<MAX_DRV_ID; i++)
    driverQ[i] = new queue<int>;
}

void setFinishTime (int t) { finishTime = t; }

void launch() {
  int nstime = 0;
  //Verilated::commandArgs(argc, argv);
  Vbench_rrmux* top = new Vbench_rrmux;
  top->reset = 1;

  while (!Verilated::gotFinish() && (nstime < finishTime)) { 
    if (nstime > 100) top->reset = 0;
    if (nstime & 1) top->clk = 1; 
    else top->clk = 0;
    top->eval(); 
    nstime++;
  }
}

void addDpiDriverData (int driverId, int data) {
  if ((driverId >=0) && (driverId < MAX_DRV_ID))
    driverQ[driverId]->push (data);
}

//int add (int a, int b) { return a+b; }
int getDpiDriverData (int driverId)
{
  int rv;
  if ((driverId >=0) && (driverId < MAX_DRV_ID)) {
    if (driverQ[driverId]->empty())
      return -1;
    else {
      rv = driverQ[driverId]->front();
      driverQ[driverId]->pop();
    }
    return rv;
  } else return -1;
}

