This is a testbench to test and verify, the behavior of the generic_dpram_dualclock. Since, it depends on the generic values, how the user can use this core, there are 6 different test cases tested. The generic that remain constant are:
  - `g_data_width`               : 32 bits
  - `g_size`                     : 32 bits
  - `g_addr_conflict_resolution` : "read_first"
  - `g_init_file`                : ""
  - `g_fail_if_file_not_found`   : true

So, the only generics that change are: 
  - `g_with_byte_enable`  : true/false
  - `g_addr_conflict_resolution` : "read_first" / "write_first" / "don't care"

Two diffent stimulus exist for the port A and B of the dpram. OSVVM methodology is being used and randomized seed for the inputs. The testbench receives only random input and later (through assertions) it compare the output of the testbench with the one from RTL, no matter what approach is being tested. This comparison is done with both RAM A and B.

