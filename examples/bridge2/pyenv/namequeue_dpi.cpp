/// @file namequeue_dpi.cpp
/// @author Guy Hutchison
/// @brief  DPI wrapper calls for accessing the namequeue

#include "namequeue.h"

map<char*,packet_t*> pktmap;

#if defined(__cplusplus)
extern "C"
{
#endif

  //import "DPI-C" function void nq_insert_open_packet (input char* qname);
void nq_insert_open_packet (char* qname)
{
  pktmap[qname] = new packet_t();
}

  //import "DPI-C" function void nq_insert_add_byte (input char* qname, input bit [7:0] dbyte);
void nq_insert_add_byte (char* qname, int dbyte)
{
  pktmap[qname]->push_back(dbyte);
}

  //import "DPI-C" function void nq_insert_close_packet (input char* qname);
void nq_insert_close_packet (char* qname)
{
  namequeue* nh;
  nh = nh->getPtr();
  nh->insert_packet(qname,pktmap[qname]);
  delete pktmap[qname];
}

  // queue size checks
  //import "DPI-C" function integer nq_queue_size (input char* qname);
int nq_queue_size (char* qname)
{
  namequeue* nh;
  nh = nh->getPtr();
  return nh->queue_size(qname);
}

  //import "DPI-C" function integer nq_queue_empty (input char* qname);
int nq_queue_empty (char* qname)
{
  namequeue* nh;
  nh = nh->getPtr();
  return nh->queue_empty(qname);
}

  //import "DPI-C" function void nq_get_packet (input char* qname, output bit [7:0] out_pkt[]);
  // Ugly trio of calls as workaround for Verilator inability to retreive
  // a packet array
  //import "DPI-C" function integer nq_get_open_packet (input char* qname);
int nq_get_open_packet (char* qname)
{
  namequeue* nh;
  nh = nh->getPtr();
  pktmap[qname] = nh->get_packet(qname);
}

  //import "DPI-C" function integer nq_get_length_packet (input char* qname);
int nq_get_length_packet (char* qname)
{
  return pktmap[qname]->size();
}

  //import "DPI-C" function bit [7:0] nq_get_byte_packet (input char* qname);
int nq_get_byte_packet (char* qname)
{
  int f = pktmap[qname]->front();
  pktmap[qname]->erase(pktmap[qname]->begin());
  return f;
}

  //import "DPI-C" function bit [7:0] nq_get_close_packet (input char* qname);
int nq_get_close_packet (char* qname)
{
  delete pktmap[qname];
}

#if defined(__cplusplus)
}
#endif
