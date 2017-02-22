Delayed Flow Control
--------------------

The Delayed Flow Control protocol is an alternate protocol to srdy-drdy designed
for top level interconnect between placement blocks.  Instead of obeying
cycle-by-cycle flow control, as srdy-drdy does, the delayed flow control
protocol assumes that flow control signals will be pipelined from their
source block to the destination block.

The delayed flow control protocol is designed such that both the forward
data/valid signals and the reverse fc_n signal can be arbitrarily pipelined
by simple flops.  The dfc_receiver implements a FIFO and thresholds such
that it will assert flow control early enough that the FIFO will not
overflow.

In order for the dfc_receiver to work properly, it needs to be parameterized
with the round-trip delay of the signal, i.e. the number of times data/valid
was flopped on the forward path and the number of times fc_n was flopped on the
reverse path.

DFC vs. Credit-based flow control
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

In implementing the DFC protocol there numerous discussions about DFC vs.
credit protocols.

Credit protocols are well understood and in numerous use.  Their advantages are
that they are more tolerant to changes in latency and more tuneable to bursty
traffic, as you can provision less credit than the round-trip delay, and
unexpected latency (by adding more flops in the PD cycle) results in graceful
degradation of performance.

The disadvantage of credit protocols are in synchronization and recovery.  Both
ends of a credit link need to either be reset simultaneously in order to
initialize credits or have some detection protocol to verify the other end of the
link is active.  Also any loss of a credit results in a loss of bandwidth unless
a credit recovery protocol is active.

The advantage of a DFC protocol is blocks can be reset independently and/or have
different reset latencies.  Also the DFC protocol itself will recover from missing/
lost flow control or valid signals as it works off the receive threshold,
although data will be lost absent some other recovery mechanism.

The DFC blocks in the sdlib have some features added to them to address PD
changes and graceful degradation; the net result of these is that the DFC
interface can be configured to operate as if it had reduced credit.

dfc_sender
~~~~~~~~~~

Delayed Flow Control conversion block.  Converts between srdy-drdy interface and
valid/flow control interface.  Flow control is declared as active low so that it
retains the same semantics as drdy (transmit on high).

The DFC sender block is quite simple, and effectively is a stripped-down sd_output
block which renames the two signals.  The DFC sender should be used in place of
an <<sd_output>> or <<sd_iofull>> block.

.. note::  If being used to replace an sd_iofull block, the p_fc_n signal is not
           registered by the module and should be registered by the designer.

+-------+-------------+-------------------------------------------------------+
| Name  | Valid range | Description                                           |
+=======+=============+=======================================================+
| width | 2+          | Width of the data input/output, in bits               |
+-------+-------------+-------------------------------------------------------+
| inputs| 2+          | Number of input interfaces                            |
+-------+-------------+-------------------------------------------------------+

dfc_receiver
~~~~~~~~~~~~

Delayed Flow Control conversion block.  Converts between srdy-drdy interface and
valid/flow control interface.  Flow control is declared as active low so that it
retains the same semantics as drdy (transmit on high).

The DFC Receiver block is the companion block to the DFC sender block above.
It converts back between a valid/flow control interface and an srdy-drdy
interface.  In this function it replaces an <<sd_input>> or <<sd_iofull>> block.

NOTE:  If being used to replace an sd_iofull block, the c_fc_n signal is not
       registered by the module and should be registered by the designer.

Because multiple words could be outstanding in the pipeline, some amount of data
may show up even after the flow control signal is asserted.  Because of this the
dfc_receiver block integrates a small FIFO to hold the in-flight data between
the time the flow control signal is asserted and the time data ceases to arrive.

The threshold value examines the FIFO usage and decides when to assert flow
control.  During steady-state operation (p_drdy is asserted), the FIFO usage
should remain a constant 2 words (using <<sd_fifo_c>>), and the threshold should
be set to one more (3), otherwise flow control will be needlessly asserted.

The size of the FIFO should be set to the size of the thresold value plus the
number of repeater flop banks added between dfc_sender and dfc_receiver.
Note that this includes not only the flops on the valid path but those on
the returning flow control path.

.. note:: For example, If the valid path was registered three times between sender and
          receiver and the fc_n signal registered once, then the FIFO size
          should be 3 + 1 + 3 = 7

+-----------+----------------------+----------------------------------------+
| Name      | Valid range          | Description                            |
+===========+======================+========================================+
| width     | 2+                   | Width of the data input/output, in bits|
+-----------+----------------------+----------------------------------------+
| depth     | RT delay + threshold | Depth of the overflow fifo, in words   |
+-----------+----------------------+----------------------------------------+
| threshold | 3+                   | Threshold at which to assert FC        |
+-----------+----------------------+----------------------------------------+

dfc_receiver_ctl
^^^^^^^^^^^^^^^^

In some cases a module may already contain a FIFO at its input; in this case it
would be inefficient to put a 2nd FIFO immediately in front of it.  For modules
which already contain an input FIFO, the dfc_receiver_ctl module contains only
the control logic and expects the input usage from an srdy-drdy FIFO.

The dfc_receiver_ctl takes the same parameters as dfc_receiver, but its FIFO-side
interface signals all begin with f_.

.. note::  If the FIFO is shared with functional logic it must be sized for both the
           logic needs and flow control requirements.  The flow control requirement
           is logic steady state + round trip delay as above.
