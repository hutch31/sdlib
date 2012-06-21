%module vlaunch
%{
void launch();
void setFinishTime (int t);
extern "C" void addDpiDriverData (int driverId, int data);
extern "C" int  getDpiDriverData (int driverId);
void tbInit();
 void setTargetRate (int driverId, double rate);
void setTrace (bool t);
%}

%init %{
  tbInit();
%}

void launch();
void setFinishTime (int t);
void setTrace (bool t);
extern "C" void addDpiDriverData (int driverId, int data);
extern "C" int  getDpiDriverData (int driverId);
void setTargetRate (int driverId, double rate);
