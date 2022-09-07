Testbench to verify the functionality of the gc_reset_multi_aasd general core. It uses GHDL simulator and OSVVM verification methodology. This core is using 2 generics in the entity:
  - g_clocks  : Number of clocks
  - g_rst_len : Number of clock ticks (per domain) that the input reset must remain deasserted and stable before deasserting the reset output(s)

A combination of them, create these test cases (there can be even more than them):
  - 1, 2
  - 1, 4
  - 2, 2
  - 2, 4
  - 1, 1

The testing process is very simple. It receives random input data (with random seeds). It uses a similar logic to the one that RTL uses and generates a testbench output (in case of more than one clocks). One assertion exist in the testbench to bring self-checking capabilities in it and compare the output of the testbench with the one in the RTL code. 


