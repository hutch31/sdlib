Methodology
===========

The methodology of the srdy-drdy interface (SDI) is based around certain core principles for ASIC design:

  * Interfaces are inherently unidirectional (no tristates)
  * Interfaces have varying width
  * Interfaces must support timing closure
  * Interfaces may not have data available on every clock
  * Destinations may not be able to accept data on every clock

While not all interfaces will meet all of the above criteria, the above provides a general case which almost all interfaces can fit under.  The last two points above imply some means of flow control between the source and the destination.  Many forms of flow control are possible, which have differing advantages and disadvantages for particular types of design and data patterns.  The goal of the SDI is not to provide the "right" answer but a consistent methodology and naming which is good enough for the majority of cases without imposing an undue overhead.

Signalling
~~~~~~~~~~

The SDI divides communication between two blocks into data units, where a data unit is the amount of data (width in bits) which can be transferred in a single clock.  The size of a unit is determined by the designer.  Some units may form the complete transaction between two blocks (e.g. a control token), while others may only represent part of a transaction (packet interfaces, config interfaces).

A transaction is completed when both srdy and drdy are asserted on the positive edge of a clock.

The blocks in the library are all specified in terms of the size of the data unit, not including the srdy/drdy control signals.  Any additional control signals needed between the source and the destination are part of the data unit (e.g. SOP/EOP).

srdy
^^^^

Srdy stands for "Source Ready".  Srdy assertion should follow certain rules:

  - srdy should be asserted whenever the source has data
  - data is asserted with srdy
  - srdy should remain asserted until the data unit is accepted
  - data should not change until the data unit is accepted

These rules exist to avoid deadlock conditions or inconsistent data.  All inter-block interfaces must follow these rules.  The first rule is important, as it implies that the source 'should not' look at the drdy signal to determine when it can send data.

drdy
^^^^

Drdy stands for "Destination Ready".  Drdy assertion rules:

  - drdy should be asserted whenever the destination can accept data
  - data is latched on (srdy & drdy)
  - drdy should remain asserted until a data unit is accepted

Breaking the rules
^^^^^^^^^^^^^^^^^^

There are situations in which the assertion rules cannot be met, for example a source can talk to multiple destinations and wants to send data only to those which are ready.  The assertion rules can be broken as long as 'only one' side breaks the rules.  If both sides violate the assertion rules deadlock will occur as each waits for the other.

The simplest way to resolve this is to take any area where the assertion rules cannot be met and "wrap" it with compliant interfaces.  This is done by default if designers use the timing closure interfaces, all of which meet the assertion rules.

Top-Level Protocols
^^^^^^^^^^^^^^^^^^^

While SDI is a very good intra-block signalling protocol, for large chips a different top-level
signalling protocol may be required.  If transport delays between top level blocks are large enough,
it may be necessary to add "repeaters" (banks of flops) on the data signals to meet timing.

The SD library has a pair of adapters for Delayed Flow Control (DFC), which assumes that response to
a flow control signal will take more than one cycle.  This involves two adapters.  One is a <<dfc_sender>>,
which is a straightforward adapter which registers the input and output signals and changes the
signal names.

The other adapter is <<dfc_receiver>>, which pairs some control logic with a small FIFO which is used to
absorb the in-transit data in the event that the receivers' producer interface asserts flow control.

The DFC adapters are described in more detail in the Closure section.

Usage
~~~~~

The most common usage pattern is to use the <<sd_input>> module for all interfaces where the design block is a destination, and the <<sd_output>> for all interfaces where the design block is a source.  This provides two major benefits:

  - Timing closure (all module outputs are registered)
  - Interface consistency (all assertion rules are met)

A single pipeline stage block would look as follows::

  sd_input #(.width(32)) in_hold
    (.clk(clk),.reset(reset),
     .c_srdy (in_srdy), .c_drdy (in_drdy), .c_data (in_data),
     .ip_srdy (lin_srdy), .ip_drdy (lin_drdy), ip_data (lin_data));

  always @*
    begin
      if (lin_srdy & lout_drdy)
        begin
          lout_srdy = 1;
          lin_drdy = 1;
          lout_data = lin_data;
        end
      else
        begin
          lout_srdy = 0;
          lin_drdy = 0;
          lout_data = 'bx;
        end
    end

  sd_output #(.width(32)) out_hold
    (.clk(clk),.reset(reset),
     .ic_srdy (lout_srdy), .ic_drdy (lout_drdy), .ic_data (lout_data),
     .p_srdy (out_srdy), .p_drdy (out_drdy), .
     .c_srdy (in_srdy), .c_drdy (in_drdy), .c_data (in_data),
     .ip_srdy (lin_srdy), .ip_drdy (lin_drdy), ip_data (lin_data));

Pipelining
^^^^^^^^^^

Building a multistage pipeline within a design block can also be simplified by
using SDI components.  The sd_output block can also be used as an inter-stage
timing closure element for the datapath.  This does create a potential critical
path on the drdy signal across the block, as this signal will not be registered
until it hits the <<sd_input>> block in the first stage, however each sd_output
stage only adds a single gate delay to the path.

Below is a sample three-stage pipeline.  The two sd_output blocks before the
final stage are for inter-stage timing closure.

Pipelined blocks::

  +----------+   +-----------+   +-----------+   +-----------+
  | sd_input |-->| sd_output |-->| sd_output |-->| sd_output |
  |  stage 1 |   |  stage 1  |   |  stage 2  |   |  stage 3  |
  +----------+   +-----------+   +-----------+   +-----------+

Pipelines may also need to incorporate elements within them which contain their
own internal pipeline.  An example of this would be a memory with a 2-cycle latency.
These can be incorporated by keeping a parallel chain of valid state flops, and
then gating the clock to the entire group when the output drdy is low.  The code
fragment below shows a sample such block::

  mem_2cycle sample_mem
    (.clk (gated_clk),
     .rd_data(rd_data),
     .rd_en  (rd_en_s0),
     ...
     );

  always @(posedge gated_clk)
    begin
      rd_en_s1 <= rd_en_s0;
      rd_en_s2 <= rd_en_s1;
    end

  assign gated_clk = clk & (!vld | drdy_s2);

Area
^^^^

As the library components are all parameterizable, the are of the blocks depends
on the parameters they are instantiated with.  Most blocks have a width parameter,
and for sufficiently large widths (>16-32) the area of the component is dominated
by the number of flops.  The table below shows the approximate flop count for
some common components.

+------------+------------+
| Name       | Flop Count |
+============+============+
| sd_input   |  W         |
+------------+------------+
| sd_output  |  W         |
+------------+------------+
| sd_iohalf  |  W         |
+------------+------------+
| sd_iofull  |  2*W       |
+------------+------------+
| sd_iosync  |  2*W       |
+------------+------------+
| sd_fifo_s, |  D*W       |
| sd_fifo_c  |            |
+------------+------------+
| sd_fifo_b  | (D+2)*W    |
+------------+------------+

W stands for width, and D for depth for the FIFO components.
