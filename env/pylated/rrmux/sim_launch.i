%module vlaunch
%{
void launch();
void setFinishTime (int t);
void addDpiDriverData (int driverId, int data);
void tbInit();
extern "C" void getTargetRate (double* rate);
extern "C" void setTargetRate (double rate);
%}

%init %{
  tbInit();
%}

void launch();
void setFinishTime (int t);
void addDpiDriverData (int driverId, int data);
extern "C" void getTargetRate (double* rate);
extern "C" void setTargetRate (double rate);
