
// Address size for number of ports.  Default value 4,
// which will allow design to scale up to 16 ports
`define PORT_ASZ    4

// We will have only 4 ports in our sample design
`define NUM_PORTS   4

// Data structure from parser to FIB.  Contains MAC DA,
// MAC SA, and source port
`define PAR_DATA_SZ (48+48+4)
`define PAR_MACDA    47:0
`define PAR_MACSA    95:48
`define PAR_SRCPORT  99:96

// number of entries in FIB table
`define FIB_ENTRIES   256
`define FIB_ASZ       $clog2(`FIB_ENTRIES)

// FIB entry definition
`define FIB_ENTRY_SZ  60
`define FIB_MACADDR   47:0     // MAC address
`define FIB_AGE       55:48    // 8 bit age counter
`define FIB_PORT      59:56    // associated port

`define FIB_MAX_AGE   255      // maximum value of age timer

`define MULTICAST     48'h0100000000  // multicast bit

// Packet control codes
`define PCC_SOP     2'b01    // Start of packet
`define PCC_DATA    2'b00    // data word
`define PCC_EOP     2'b10    // End of packet
`define PCC_BADEOP  2'b11    // End of packet w/ error

// Packet FIFO Word
// uses same field definitions as Packet Ring Word, but no PVEC bit
`define PFW_SZ 69

// Port FIFO sizes
`define RX_FIFO_DEPTH 256
`define TX_FIFO_DEPTH 1024

`define RX_USG_SZ     $clog2(`RX_FIFO_DEPTH)+1
`define TX_USG_SZ     $clog2(`TX_FIFO_DEPTH)+1

// Packet Ring Word

`define PRW_SZ       70
`define PRW_DATA     63:0      // 64 bits of packet data
`define PRW_PCC      65:64     // packet control code
`define PRW_VALID    68:66     // # of valid bytes modulo 8
`define PRW_PVEC     69        // indicates this is port vector word

// GMII definitions
`define GMII_PRE     8'h55
`define GMII_SFD     8'hD5
