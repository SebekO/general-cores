This is a testbench for xwb_crossbar. This simple self-checking testbench, is for the case where there are 1 master and 2 slaves. The core can be used for MxN.
OSVVM methodology is used and random inputs drive the testbench (based on randomized seed number).

When no master granted access to SDB, the slaves are in stall and wait for access. When this signal `sdb_sel_o` is not zero, the output master and slaves, are equal to the pointing slaves and master respectively.  
