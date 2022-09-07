Testbench to verify the functionality of the gc_single_reset_gen general core. It uses GHDL simulator and OSVVM verification methodology. This core is having 2 generics in the entity:
  - g_out_reg_depth : Number of Flip-Flos before the signal's output
  - g_rst_in_num    : Number of input async reset signals

The testcases of the testbench can arise from a combination of these generics. There can be many testcases, but in here there are tested the following: (1,1), (2,2), (4,5), (2,8).

The testing process is very simple. It receives random input data (with random seeds). It uses a similar logic to the one that RTL uses and generates a testbench output. Some assertions exist in the testbench to bring self-checking capabilities in it, which are:
  - Check that the number of f/f before the final signals' output is valid 
  - Check that number of asynchronous reset signals is valid
  - Compare the output reset of testbench to be the same as the one from RTL core
  - Reset to not be asserted before the powerup

Simple coverage is being covered also:
  - Powerup has done (at least 1 time per simulation)
