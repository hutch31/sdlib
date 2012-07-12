/*! \file namequeue.h
 * \author Guy Hutchison
 * \copyright 2012, Guy Hutchison
 * \brief Name-based Queue Class Definition
 */
 
/* Copyright (c) 2011, Guy Hutchison
   All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
    * Neither the name of the author nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#ifndef _NAMEQUEUE_H
#define _NAMEQUEUE_H

#include <vector>
#include <deque>
#include <map>
#include <stdint.h>
//#include <string>
using std::vector;
using std::deque;
using std::map;
//using std::string;

//typedef pair<string,int> namePair;

/// Defines a packet type as a byte vector
typedef vector<uint8_t> packet_t;

typedef packet_t::iterator packet_i;
typedef deque<packet_t> packet_queue_t;

/**
 * @brief Name-based packet queue
 *
 * Creates a set of queues storing "packets", which are defined as byte-vectors
 * of arbitrary length.  Definition and use of a queue are based on a text string.
 *
 * Queues are allocated automatically when data is inserted into them.  Queues which
 * have not been allocated appear empty until written to.
 *
 * The class provides multiple methods of dequeueing.  The front_size(), front_iter()
 * and remove_packet() trio of methods allow discrete inspection, access to and removal
 * of the packet at the front of the queue without requiring any memory allocation.
 *
 * The single get_packet() call encapsulates packet retreival and removal into a single
 * call, however requires the caller to delete the object returned.
 *
 * The queue_size() and queue_empty() calls can be used to query the depth or empty
 * state of the queue, without causing dynamic queue creation.
 *
 * Namequeue is defined as a singleton, so there can only be one instance of namequeue
 * in a simulation.  Modules get access to the namequeue by calling getPtr().
 */
//class namequeue;

class namequeue {
 private:
  map<char*,packet_queue_t *> qmap;
  //int nxt_queue;
  void checkName (char* name);
  static namequeue* _instance;
 protected:
  namequeue();
 public:
  /// get pointer to the namequeue class
  /// @returns Pointer to namequeue instance
  static namequeue* getPtr();

  /// Insert a packet in the named queue
  /// If the named queue does not exist, it will be created prior to
  /// inserting the packet.
  /// @param name Name of queue to insert
  /// @param pkt  Packet vector to insert
  int insert_packet (char* name, packet_t *pkt);

  /// Return length of the named queue in number of packets
  /// @param name Name of queue
  int queue_size (char* name);

  /// Check queue empty
  /// @param name Name of queue
  /// @returns True if queue is empty, false otherwise
  bool queue_empty (char* name);

  /// Return a packet iterator to the packet at the front of the queue.
  /// This call should be qualified by queue_size() or queue_empty() calls
  /// prior to calling.
  /// @param name Name of queue
  //packet_i front_iter (char* name);

  
  /// Return the size of the packet at the front of the queue
  /// @param name Name of queue
  /// @returns The size of the head packet in bytes, -1 if queue empty
  int front_size (char* name);

  /// Remove a packet from the front of the queue
  /// @param name Name of queue
  /// @returns 1 on successful packet removal, 0 if queue was empty
  int remove_packet (char* name);

  /// Copy the packet object and return a pointer to the new packet object
  /// Caller is responsible for delete on the returned object pointer
  /// @param name Name of queue
  /// @returns Pointer to first packet on the queue, returns null if queue empty
  packet_t *get_packet (char* name);
};

#endif
