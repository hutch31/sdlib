#include "Venv_top.h"
#include "verilated.h"
#include "verilated_vcd_c.h"

// includes for DPI call
#include "svdpi.h"
#include "Venv_top__Dpi.h"
#include <queue>

#define MAX_DRV_ID 64

static int finishTime = 1000;
queue<int> *driverQ[MAX_DRV_ID];
double targetRate[MAX_DRV_ID];
bool traceOn;

double sc_time_stamp () {
  return 0.0;
}

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
  Venv_top* top = new Venv_top;

  top->reset = 1;
  if (traceOn) {
    top->trace (tfp, 99);
    tfp->open ("env_top.vcd");
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

