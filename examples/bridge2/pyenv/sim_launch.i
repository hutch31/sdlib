%module vlaunch
%include "std_vector.i"
%include "std_map.i"
%include "std_deque.i"
%{
#include "namequeue.h"
void launch();
void setFinishTime (int t);
void tbInit();
void setTargetRate (int driverId, double rate);
void setTrace (bool t);
%}
%include "namequeue.h"

//%typemap(in) packet_t* {
//  $1 = new packet_t();
//  len = PyList_Size($input);
//  for (int i=0; i<len; i++) {
//    $1->push_back (PyInt_Check(PyList_GetItem($input,i)));
//  }
//}

//%typemap(out) packet_t* {
//  int len = $1.size();
//  PyObject *rv = PyList_New (len);
//  for (int i=0; i<len; i++) {
//    PyList_SetItem (rv, i, PyInt_Check($1[i]));
//  }
//  delete $1;
//  $result = rv;
//}

%init %{
  tbInit();
%}

void launch();
void setFinishTime (int t);
void setTrace (bool t);
void setTargetRate (int driverId, double rate);

