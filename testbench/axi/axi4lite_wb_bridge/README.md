This is the testbench for the axi4lite to wishbone bridge (axi4lite_wb_bridge).
In this core, the Master is AXI4 Lite and Slave is Wishbone.

For the development of the RTL core and the testbench, the documentation that
taken into account is : "AMBA AXI and ACE Protocol Specification".

NOTE: You can change the simulation time by changing the NOW variable in the stimulus

The testing process is the following:
  - Randomized inputs are given to the Design Under Test, both for Master and Slave
  - FSM coverage is printed in the end.
  - Assertions are used to check the functionality of the AXI4-Lite and Wishbone protocols


