This is a testbench in order to verify the behavior of the axi4lite to axi4full
bridge. Master is the axi4lite and the slave is axi4full.

For the development of the RTL core and the testbench, the documentation that
taken into account is : "AMBA AXI and ACE Protocol Specification".

NOTE: You can change the simulation time by changing the NOW variable in the stimulus

The testing process is the following:
  - Randomized inputs are given to the Design Under Test
  - FSM coverage is printed in the end.
  - Assertions are used to check the functionality of the AXI4-Full and AXI4-Lite protocols

