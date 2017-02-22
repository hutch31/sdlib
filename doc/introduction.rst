Introduction
============

The srdy-drdy library provides a common specification for unidirectional data interfaces with bidirectional flow control. The library also provides a set of common modules with compliant interfaces.

Naming Conventions
~~~~~~~~~~~~~~~~~~

A 'data unit' is the amount of data transferred in a single transaction.  An 'interface' is
a group of srdy, drdy, and one or more data signals.  An interface where srdy is an output is
a 'producer' interface, and one where srdy is an input is a 'consumer' interface.

Verification Status
~~~~~~~~~~~~~~~~~~~

Most of the components included in this library have been actively used in multiple silicon
tapeouts, and are considered known good.  Nonetheless users of the library should validate
proper operation of the components in their designs.  Where applicable components which are
not known to have been used in working silicon have been flagged.

The example designs provided have not been validated in silicon, and should be used only as
an illustration of use of the SDI component library and use of the SDI in custom-written
blocks.
