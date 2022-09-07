This is a testbench to test and verify, the behavior of the generic_dpram_split. There is only one testcase being tested since the generic values have chosen to remain stabel (as there can not be generated other test cases from them): 

  - g_size                     = 16384
  - g_addr_conflict_resolution = "read_first"
  - g_init_file                = ""
  - g_fail_if_file_not_found   = true
  
One stimulus exist since there is only one clock domain. OSVVM methodology is being used and randomized seed for the inputs. The testbench receives only random input and later (through assertions) it compares the output of the testbench with the one from RTL depending on the test case that is being tested. Two assertions exist, one for each RAM port. 

