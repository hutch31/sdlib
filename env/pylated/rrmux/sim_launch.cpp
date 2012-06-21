#include "Vbench_rrmux.h"
#include "verilated.h"
#include "verilated_vcd_c.h"

// includes for DPI call
#include "svdpi.h"
#include "Vbench_rrmux__Dpi.h"
#include <queue>

#define MAX_DRV_ID 64

static int finishTime = 1000;
queue<int> *driverQ[MAX_DRV_ID];
double targetRate[MAX_DRV_ID];
bool traceOn;

void tbInit () {
  for (int i=0; i<MAX_DRV_ID; i++) {
    driverQ[i] = new queue<int>;
    targetRate[i] = 1.0;
  }
  traceOn = false;
}

void setFinishTime (int t) { finishTime = t; }

void setTrace (bool t) { traceOn = t; }

void launch() {
  int nstime = 0;
  //Verilated::commandArgs(argc, argv);
  Verilated::traceEverOn(traceOn);
  VerilatedVcdC *tfp = new VerilatedVcdC;
  Vbench_rrmux* top = new Vbench_rrmux;

  top->reset = 1;
  if (traceOn) {
    top->trace (tfp, 99);
    tfp->open ("rrmux.vcd");
  }

  while (!Verilated::gotFinish() && (nstime < finishTime)) { 
    if (nstime > 100) top->reset = 0;
    if (nstime & 1) top->clk = 1; 
    else top->clk = 0;
    top->eval(); 
    tfp->dump (nstime);
    nstime++;
  }
  if (traceOn) tfp->close();
}

double getTargetRate (int driverId) {
  return targetRate[driverId];
}

void setTargetRate (int driverId, double rate) {
  targetRate[driverId] = rate;
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

