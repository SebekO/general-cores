This is a testbench to verify the functionality of gc_dyn_extend_pulse. The core, generates a pulse of programmable width upon detection of a rising edge in the input. With this test, we check that this pulse will not be higher than the len_i, which is specified by the generic `g_len_width`. 

This testbench is running with GHDL and OSVVM verification methodology is used. Randomized input signals with random seed is used in every run. Currently there are three test cases, where the length is 2, 4 and 6 clock cycles.

Some simple coverage is being achieved for these cases:
  - when the reset is asserted (at least once)
  - when the input and output pulses are both HIGH
  - when input pulse is LOW and output pulse is HIGH
