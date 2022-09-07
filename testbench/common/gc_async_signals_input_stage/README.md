Summary of test cases : 

  1. One clock and one reset to handle
  2. Coming input async signals (can be more than one)
  3. config_active_i goes with each input signal. Actually
     this is the one that say if the pulses produced on falling edge

  ** this can be always high, always zero, and random 

  4. The output (signals_o) is synchronized to our clock
  5. Now, depending on config_active_i, we have different values of the output
     signals, signals_p1_o, signals_pN_o. The first one is HIGH if config HIGH
     and is the "identity" let's say of the output signal.
     The latter can be the same if we activate (more than 0) of g_extended_pulse_width.

The testing process is the following: Assign random input data using OSVVM, to verify the functionality 
of the RTL core. In addition, a few assertions added in the testbench, for all the signals.


