This is a simple testbench which uses GHDL simulator and OSVVM verification methodology. The goal is to verify the functionality of the gc_negedge (a simple falling edge detector). Through OSVVM, we can achieve randomization of the input data, with randomized seed value. The test cases of the testbench are defined through the different values assigned to the entity's generics. 

The generics of this core are the following:
  - g_async_rst  : Synchronous or asynchronous reset
  - g_clock_edge : Clock edge sensitivity of edge detection

Regarding on the values of the above generics, there are the following test cases:
  1. TRUE, positive
  2. TRUE, negative
  3. FALSE, positive
  4. FALSE, negative

Assertions are used to provide a self-checking approach. These are:
  - The width of the output pulse is always one clock cycle long
  - To always detect a negative edge of a falling input data signal

Coverage that is being covered:
  - Reset has been asserted
  - Input pulse detected
  - Output pulse detected

Note: The values of the two last coverage bins are different because the input signal width is not always one clock cycle long
