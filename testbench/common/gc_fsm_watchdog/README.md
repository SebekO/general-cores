This is a testbench to verify the gc_fsm_watchdog core. It uses GHDL simulator and OSVVM as verification methodology. All input signals in the testbench are random, with random seed also.

There are 4 test cases, depending on the value of the watchdog timer (1, 2, 4, 8). This can be extended more and have more test cases, but for simulation reasons it is preferred to give to this generic, a lower value. In case of an increase in this value, please increase also the simulation time (ex. NOW)

There is also one assertion, to give to the testbench a more self-checking approach:
  - Check that output signal (fsm_rst_o) is HIGH when the internal counter reaches the maximum value of the watchdog timer 

Simple coverage is being covered:
  - Reset has been asserted
  - Output fsm reset asserted 
