Testbench to verify the functionality of the gc_rr_arbiter general core. It uses GHDL simulator and OSVVM verification methodology. The test cases of this testbench arise from the g_size generic and they are : 1, 3, 7, 16, 31, 128. 

The testing process is the following: It receives random input data (with random seeds). Two assertions are being used to bring self-checking capabilities in the testbench:
  1. Output grant_o is the delayed (by 1 clock cycle) version of grant_comb_o
  2. The valid values of grant_comb_o are 0, 1.

An example to the second assertion is the following, for g_size = 3:

    req_i   grant_o
    000     000
    001     001
    010     010
    011     010 / 001
    100     100
    101     100 / 001
    110     100 / 010
    111     100 / 010 / 001

Note: It is advised, for simulation purposes, to keep the generic values quite low in order to see the behavior of the module. For higher generic values, increase the simulation time.

