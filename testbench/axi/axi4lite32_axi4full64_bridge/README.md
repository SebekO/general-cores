This is a testbench in order to verify the behavior of the axi4lite 32-bits
to axi4full 64-bits, bridge. Master is the axi4lite and the slave is axi4full.
For the development of the RTL core and the testbench, the documentation that
taken into account is : "AMBA AXI and ACE Protocol Specification". OSVVM used
as verification methodology and GHDL is the simulator.

NOTE: You can change the simulation time by changing the NOW variable in the stimulus

The testing process is the following:
  - Randomized inputs are given to the Design Under Test
  - FSM coverage is printed in the end.
  - Assertions are used to check the functionality of the AXI4-Full and AXI4-Lite protocols

