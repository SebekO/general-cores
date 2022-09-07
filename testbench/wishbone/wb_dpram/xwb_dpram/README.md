This is a testbench for the xwb_dpram. In the input side there are 2 slave (slave1 and slave2), both of their inputs are randomized, with random seed in every run. In the output side there are again 2 slave (slave1 and slave2). This purpose of the test is to verify the functionality of the core. In order to cover all the possible ways that someone can use this core, regarding the values of the generics. Some of the values remain steady:

  - `g_size`                : 32-bits
  - `g_init_file`           : none
  - `g_must_have_init_file` : true  

The testcases are created based on the:

  - `g_slave1_interface_mode` : CLASSIC / PIPELINED
  - `g_slave2_interface_mode` : CLASSIC / PIPELINED
  - `g_slave1_granularity`    : WORD / BYTE
  - `g_slave2_granularity`    : WORD / BYTE

OSVVM is used as the verification methodology of the testbench. Various assertions are used in order to confirm that:

  - ACK signals are behave as they supposed to be (depending the `stb` and `cyc` of the input
  - ERR, RTY, and STALL are always zero in the output
  - Output data of the slaves is the expected (regarding the value of the interface mode and granularity, the output data can have different behavior)
