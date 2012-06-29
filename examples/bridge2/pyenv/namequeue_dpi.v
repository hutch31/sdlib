  //import "DPI-C" function integer nq_insert_packet (input string qname, input bit [7:0] in_pkt[]);
  // Ugly trio of calls as workaround for Verilator inability to retreive
  // a packet array
  import "DPI-C" function void nq_insert_open_packet (input string qname);
  import "DPI-C" function void nq_insert_add_byte (input string qname, input bit [7:0] dbyte);
  import "DPI-C" function void nq_insert_close_packet (input string qname);

  // queue size checks
  import "DPI-C" function integer nq_queue_size (input string qname);
  import "DPI-C" function integer nq_queue_empty (input string qname);

  //import "DPI-C" function void nq_get_packet (input string qname, output bit [7:0] out_pkt[]);
  // Ugly trio of calls as workaround for Verilator inability to retreive
  // a packet array
  import "DPI-C" function integer nq_get_open_packet (input string qname);
  import "DPI-C" function integer nq_get_length_packet (input string qname);
  import "DPI-C" function bit [7:0] nq_get_byte_packet (input string qname);
  import "DPI-C" function bit [7:0] nq_get_close_packet (input string qname);

