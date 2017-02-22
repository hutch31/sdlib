Timing Closure Components
-------------------------

The timing closure components are intended for designing custom blocks and pipeline
stages.  Each block provides timing closure for block outputs, or for block inputs
and outputs.

The two most common design methodologies today are registered-output (RO) and
registered-input-registered-output (RIRO).  The library is generally built around
an assumption of an RO design style but also supports RIRO.

Note that the two styles are not mutually exclusive; a given project might specify that
all blocks should use an RO style and superblocks (floorplan units) should use RIRO.

For components which support synchronization across clock domains, the sync flops are
all prefixed with hgff_ for replacement during synthesis with high-gain flip flops.

sd_input
~~~~~~~~

When using an RO design style, the sd_input provides timing closure for a block's
consumer interface.  The only block output for the consumer interface is c_drdy.
sd_input also provides a one-word buffer on c_data, but doesn't provide timing
closure for this input.

.. table:: Parameter description
+-------+-------------+-------------------------------------------------------+
| Name  | Valid range | Description                                           |
+=======+=============+=======================================================+
| width | 2+          | Width of the data input/output, in bits               |
+-------+-------------+-------------------------------------------------------+

sd_output
~~~~~~~~~

The sd_output is the companion block to sd_input, providing timing closure for a
block's producer interface (or interfaces).  It provides timing closure on p_srdy
and p_data.

.. table:: Parameter description
+-------+-------------+-------------------------------------------------------+
| Name  | Valid range | Description                                           |
+=======+=============+=======================================================+
| width | 2+          | Width of the data input/output, in bits               |
+-------+-------------+-------------------------------------------------------+

sd_iohalf
~~~~~~~~~

The sd_iohalf can be used as either an input or output timing closure block, as
it closes timing on all of its inputs and outputs.  It has an efficiency of 0.5,
meaning it can only accept data on at most every other clock, so it is useful for
low-rate interfaces.

.. table:: Parameter description
+-------+-------------+-------------------------------------------------------+
| Name  | Valid range | Description                                           |
+=======+=============+=======================================================+
| width | 2+          | Width of the data input/output, in bits               |
+-------+-------------+-------------------------------------------------------+

sd_iofull
~~~~~~~~~

This block can be used with a RIRO design style to provide timing closure for
all of a block's inputs and outputs.  Combines an sd_input and sd_output.
This is not a "pure" registered input block but there are no more than 2-3 levels
of logic before the input is registered.

.. table:: Parameter description
+-------+-------------+-------------------------------------------------------+
| Name  | Valid range | Description                                           |
+=======+=============+=======================================================+
| width | 2+          | Width of the data input/output, in bits               |
+-------+-------------+-------------------------------------------------------+
