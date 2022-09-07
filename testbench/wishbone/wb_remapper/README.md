Simple testbench for a Wishbone bus address remapper core. It uses OSVVM methodology with all the  input signals in the stimulus to be get random values in each clock cycle. The simulation time, can be changed in the `stim` process, by changing the value of `NOW`. There is one test case which checks the functionality of the core.  

Self-Checking: Two assertions are being implemented, to enhance the testing process. One of them test if there is mismatch between the input master and output slave and the other check if there is a mismatch between output master and input slave.  

Note: Since there is no clock or reset signal, a delay of 10ns added to the processes, for simulation reasons.
