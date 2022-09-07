Testbench to verify the functionality of the gc_serial_dac general core. It uses GHDL simulator and OSVVM verification methodology. This core is using 4 generics in the entity:
  - g_num_data_bits  : Number of DAC data word bits, LSBs
  - g_num_extra_bits : Number of padding MSBs sent as zeros
  - g_num_cs_select  : Number of chip select inputs
  - g_sclk_polarity  : Serial clock polarity (0 for rising, 1 for falling edge)

A combination of them, create these test cases (there can be even more than them):
  1. 2, 0, 1, 0
  2. 2, 1, 2, 0
  3. 4, 4, 2, 0
  4. 16,8, 1, 0
  5. 2, 0, 1, 1
  6. 4, 2, 1, 1
  7. 8, 4, 2, 1
  8. 16,8, 2, 1

The testbench, receives random input data (with random seeds). It uses a similar logic to the one that RTL uses and generates a testbench output. One assertion exist in the testbench to bring self-checking capabilities in it and compare the output of the testbench with the one in the RTL code. 

Simple coverage is being covered also:
  - Reset has been asserted
  - DAC is not busy

Note: It is advised, for simulation purposes, to keep the generic values quite low in order to see the behavior of the module. For higher generic values, increase the simulation time.

