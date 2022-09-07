This is a testbench to verify the gc_frequency_meter core. It uses GHDL simulator and OSVVM as verification methodology. All input signals in the testbench are random, with random seed also.

The generics of the core are:
  - g_with_internal_timebase : Specifies from where the period is defined
  - g_clk_sys_freq           : Frequency of system clock
  - g_sync_out               : If true, the output freq_o, belongs to the clk_sys clock domain
  - g_counter_bits           : Bit length of the counter

And the test cases that are created, depending on the values of these generics are:
  - Two bigger category, if g_with_internal_timebase is either true or false, where there are the following:
    - Different values of system clock frequency (up to 10000Hz) and g_sync_out true or false 

There are the following assertions, to give to the testbench a more self-checking approach:
  - Check for data mismatch between the testbench's output and RTL output for both choices of g_sync_out

Note: It is better to give lower values to CLK_SYS_FREQ in order for the simulation to not take loong time to finish
