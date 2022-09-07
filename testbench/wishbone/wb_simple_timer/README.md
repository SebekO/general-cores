Simple testbench for White-Rabbit PTP core tics wrapper. It uses OSVVM methodology with all the  input signals in the stimulus to be get random values in each clock cycle. The simulation time, can be changed in the `stim` process, by changing the value of `NOW`. There is one test case with:
  - g_interface_mode      : CLASSIC
  - g_address_granularity : WORD   

Self-Checking: One assertion is being implemented, to enhance the testing process. It simply checks if the difference between the RTL output data and testbench's output data, is bigger than one.
 
