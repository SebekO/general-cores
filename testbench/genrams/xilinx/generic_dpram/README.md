This is a testbench to test and verify, the behavior of the generic_dpram. Since, it depends on the generic values, how the user can use this core, there are 4 different test cases tested. The generic that remain constant are:
  - `g_data_width`               : 32 bits
  - `g_size`                     : 32 bits
  - `g_addr_conflict_resolution` : "read_first"
  - `g_init_file`                : ""
  - `g_fail_if_file_not_found`   : true

So, the only generics that change are: 
  - `g_with_byte_enable`  : true/false
  - `g_dual_clock`        : true/false

Two diffent stimulus exist for the port A and B of the dpram. OSVVM methodology is being used and randomized seed for the inputs. There are three different ways of using this core, dual clock, single clock and splitram. The testbench receives only random input and later (through assertions) it compare the output of the testbench with the one from RTL, no matter what approach is being tested.

