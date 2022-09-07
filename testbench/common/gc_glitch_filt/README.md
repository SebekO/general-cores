This is a testbench to verify the functionality of gc_glitch_filt. The core can operate differently, regarding the `g_len` generic:

  - when g_len = 0 => Output is the same as the input AFTER one clock.

  - when g_len > 0 => output becomes '1' when all the FF's are '1' and ONLY when all FF's are '0' it becomes '0' again.

This test is running with GHDL and OSVVM is used. There are 4 test cases so far with different length each time. Randomized inputs are producing with random seed.
 
