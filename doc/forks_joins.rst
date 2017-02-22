Forks and Joins
---------------

This section provides pipeline fork (split) and join blocks.  A fork refers to any
block which has multiple producer interfaces, with usually a single consumer
interface.  A join is the corresponding block with multiple consumer interfaces and
a single producer interface.

sd_mirror
~~~~~~~~~

This block is used to implement a mirrored fork, i.e. one in which all producer
interfaces carry the same data.  This is useful in control pipelines when a single
item of data needs to go to multiple blocks, which may all acknowledge at different
times.

It has an optional c_dst_vld input, which can be used to "steer" data to one or more
destinations, instead of all of them.  c_dst_vld should be asserted with c_srdy, if
it is being used.  If not used, tie this input to 0 and it will mirror to all
outputs.

Note that sd_mirror is low-throughput, as it waits until all downstream blocks have
acknoweldged before accepting another word.

+-------+-------------+-------------------------------------------------------+
| Name  | Valid range | Description                                           |
+=======+=============+=======================================================+
| width | 2+          | Width of the data input/output, in bits               |
+-------+-------------+-------------------------------------------------------+
| mirror| 2+          | Number of output interfaces                           |
+-------+-------------+-------------------------------------------------------+

sd_rrmux
~~~~~~~~

This block implements a round-robin arbiter/mux.  It has multiple modes
with options on whether a grant implies that input will "hold" the grant, or
whether it moves on.

Mode 0 multiplexes between single words of data.  Mode 1 allows an interface to burst,
so once the interface begins transmitting it can transmit until it deasserts srdy.

Mode 2 is for multiplexing data where multiple words need to be
kept together.  Once srdy is asserted, the block will not switch inputs until the
end pattern is seen, even if srdy is deasserted.

Also has a slow (1 cycle per input) and fast (immediate) arb mode.  The fast arb mode
violates the drdy assertion rules, as it monitors the incoming srdy signals and then
grants a drdy to one of the input interfaces.

+--------+-------------+-------------------------------------------------------+
| Name   | Valid range | Description                                           |
+========+=============+=======================================================+
| width  | 2+          | Width of the data input/output, in bits               |
+--------+-------------+-------------------------------------------------------+
| inputs | 2+          | Number of input interfaces                            |
+--------+-------------+-------------------------------------------------------+
| mode   | 2+          | Arbitration mode                                      |
+--------+-------------+-------------------------------------------------------+
|fast_arb| 2+          | Use single-cycle arbitration                          |
+--------+-------------+-------------------------------------------------------+

NOTE:  modes 1 and 2 have not been verified to date.
