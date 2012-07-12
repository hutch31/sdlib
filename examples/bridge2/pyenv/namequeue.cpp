//----------------------------------------------------------------------
//  Name Packet Queue Class Methods
//----------------------------------------------------------------------

/* Copyright (c) 2011, Guy Hutchison
   All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
    * Neither the name of the author nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#include "namequeue.h"


namequeue* namequeue::_instance = 0;

namequeue* namequeue::getPtr()
{
  if (_instance == 0)
   _instance = new namequeue();
  return _instance;
}

namequeue::namequeue() 
{
}

void namequeue::checkName (char* name)
{
  packet_queue_t *qptr;

  qptr = qmap[name];
  if (qptr == 0)
    qmap[name] = new packet_queue_t();
}

int namequeue::insert_packet (char* name, packet_t *pkt)
{

  checkName(name);
  qmap[name]->push_back(*pkt);
  return 0;
}

int namequeue::queue_size (char* name) {
  packet_queue_t *qptr;

  qptr = qmap[name];
  if (qptr == 0) return 0;
  else return qmap[name]->size();
}

int namequeue::remove_packet (char* name) {
  checkName(name);
  if (!qmap[name]->empty()) {
    qmap[name]->front().clear();
    qmap[name]->pop_front();
    return 1;
  } else return 0;
}

bool namequeue::queue_empty (char* name)
{
  packet_queue_t *qptr;

  qptr = qmap[name];
  if (qptr == 0) return true;
  else return qmap[name]->empty(); 
}

/*
packet_i namequeue::front_iter (char* name) {
  checkName(name);
  qmap[name]->front().begin();
}
*/

int namequeue::front_size (char* name)
{
  packet_queue_t *qptr;

  qptr = qmap[name];

  if (qptr == 0) return -1;
  else return qmap[name]->front().size();
}

packet_t *namequeue::get_packet (char* name)
{
  packet_t *pptr;

  if (queue_empty(name)) return 0;
  else {
    pptr = new packet_t();
    *pptr = qmap[name]->front();
    qmap[name]->front().clear();
    qmap[name]->pop_front();
    return pptr;
  }
}
