Buffers
-------

The buffers section of the library contains FIFOs for rate-matching and storage.
Each buffer consists of a "head" (write) block, and a "tail" (read) block, so that
the user can construct their own FIFOs from the blocks provided without having to
modify the library code.  Each buffer is built around a synthesizable memory-like
block, so the buffers can be synthesized as-is or the top-level blocks can be
used as a template for creating your own FIFO around a library-specific memory.

ECC generate/correct blocks can also be placed inside this wrapper if error
correction is needed (see https://sourceforge.net/projects/xtgenerate/ for ECC
generator/checker).

sd_fifo_c
~~~~~~~~~

The sd_fifo_c ("compact" or "count") FIFO is a synchronous-only FIFO for small,
non-power-of-two FIFOs.  It maintains an internal up-down counter that it uses for
empty/full detection.  The sd_fifo_c does not have separate head/tail blocks, as it
intended to be used as a flop-only FIFO.

Other than the above it is functionally identical to the sd_fifo_s.

.. table:: Parameter description
+-------+-------------+-------------------------------------------------------+
| Name  | Valid range | Description                                           |
+=======+=============+=======================================================+
| width | 2+          | Width of the data input/output, in bits               |
+-------+-------------+-------------------------------------------------------+
| depth | 2+          | Depth of the FIFO.  Can be any integer value.         |
+-------+-------------+-------------------------------------------------------+

sd_fifo_s
~~~~~~~~~

This "small" (or "sync") FIFO is used for rate-matching between blocks.  It also
has built-in grey code conversion, so it can be used for crossing clock domains.
When the "async" parameter is set, the FIFO switches to using grey code pointers,
and instantiates double-sync flops between the head and tail blocks.

sd_fifo_s can only be used in natural powers of 2, due to the async support.

.. table:: Parameter description
+-------+-------------+-------------------------------------------------------+
| Name  | Valid range | Description                                           |
+=======+=============+=======================================================+
| width | 2+          | Width of the data input/output, in bits               |
+-------+-------------+-------------------------------------------------------+
| depth | 4+          | Depth of the FIFO.  Must be a natural power of 2.     |
+-------+-------------+-------------------------------------------------------+
| async | 0/1         | When set to 1, FIFO supports asynchronous behavior    |
|       |             | with separate read and write clocks.                  |
+-------+-------------+-------------------------------------------------------+

sync operation
^^^^^^^^^^^^^^

When the core is used as a synchronous core, the two input clock and input reset
signals should be tied to the same clock and reset, respectively.  The two usage
counters will read the same value; the user should use one usage counter and leave
the other counter disconnected.

async support
^^^^^^^^^^^^^

The sd_fifo_head_s and sd_fifo_tail_s have separate usage counters available.
Each usage counter is specific to the clock domain it operates in.  If the core
is in async mode, the two usage counters may display different values during
operation due to the cycle delay of pointers crossing the clock domain.

sd_fifo_head_s
^^^^^^^^^^^^^^

This sub-block is the head (write) half of the FIFO.  It controls pointers only and
does not have a data input; data should be written directly to the memory.

sd_fifo_tail_s
^^^^^^^^^^^^^^

This sub-block is the tail (read) half of the FIFO.  It controls pointers only and
does not have a data input; FIFO output data comes directly from the memory.  The
tail block assumes memory has a single cycle of read latency.
