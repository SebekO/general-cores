Testbench to verify the functionality of the gc_reset general core. It uses GHDL simulator and OSVVM verification methodology. This core is using 3 generics in the entity:
  - g_clocks    : Number of clocks 
  - g_logdelay  : Delay duration
  - g_syncdepth : Synchronization depth

A combination of them, create these test cases (there can be even more than them):
  - 1, 1, 1
  - 2, 2, 2
  - 1, 5, 3
  - 4, 3, 4

The testing process is very simple. It receives random input data (with random seeds). It uses a similar logic to the one that RTL uses and generates a testbench output. One assertion exist in the testbench to bring self-checking capabilities in it and compare the output of the testbench with the one in the RTL code. 

Simple coverage is being covered also:
  - Asynchronous reset has been asserted
  - Output reset has been asserted

Note: It is advised, for simulation purposes, to keep the generic values quite low in order to see the behavior of the module. For higher generic values, increase the simulation time.

