%module vlaunch
%{
void launch();
void setFinishTime (int t);
void addDpiDriverData (int driverId, int data);
void tbInit();
 void setTargetRate (int driverId, double rate);
%}

%init %{
  tbInit();
%}

void launch();
void setFinishTime (int t);
void addDpiDriverData (int driverId, int data);
void setTargetRate (int driverId, double rate);
