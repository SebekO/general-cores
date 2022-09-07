Testbench to verify the functionality of the gc_pulse_synchronizer general core. It uses GHDL simulator and OSVVM verification methodology. Since in this core there are no generics in the entity, there is only one test case.

The testing process is very simple. It receives random input data (with random seeds). One assertion exist in the testbench to bring self-checking capabilities in it. What it does is that, after the de-assertion of ready_o, checks if, in the next rising edge of clock, the output is HIGH. 

Simple coverage is being covered also:
  - Reset has been asserted
  - New HIGH data arrived
  - New valid HIGH data produced
 
