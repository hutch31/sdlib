Memory
------

Contains synthesizable memories implemented as flops.  These correspond to the
commonly used registered-output memories available in most technologies.

behave1p_mem
~~~~~~~~~~~~

Single (1RW) port behavioral memory model with a synchronous read port.

+-------+-------------+-------------------------------------------------------+
| Name  | Valid range | Description                                           |
+=======+=============+=======================================================+
| width | 2+          | Width of the data input/output, in bits               |
+-------+-------------+-------------------------------------------------------+
| depth | 4+          | Memory depth in words                                 |
+-------+-------------+-------------------------------------------------------+

behave2p_mem
~~~~~~~~~~~~

Dual (1R-1W) port behavioral memory model with a synchronous read port.

+-------+-------------+-------------------------------------------------------+
| Name  | Valid range | Description                                           |
+=======+=============+=======================================================+
| width | 2+          | Width of the data input/output, in bits               |
+-------+-------------+-------------------------------------------------------+
| depth | 4+          | Memory depth in words                                 |
+-------+-------------+-------------------------------------------------------+
