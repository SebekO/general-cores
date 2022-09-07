Testbench for Atmel EBI asynchronous bus <-> Wishbone bridge. It is using OSVVM methodology with all the  input signals in the stimulus to be get random values in each clock cycle. The simulation time, can be changed in the `stim` process, by changing the value of `NOW`. Regarding on the values that the generics of the core have, there are at least 4 test cases presented:

  - g_simulation          :    1 / 0 
  - g_address_granularity : WORD / BYTE
  - g_cpu_address_width   :   32 / 64

Self-Checking: A few assertions are being implemented, in order to test the functionality of the core. First of all, they check if there is an address mismatch, between the RTL and the testbench's output address. There is another assertion that checks if there is a mismatch in output data as well, when the read and write pulse are both asserted. 
