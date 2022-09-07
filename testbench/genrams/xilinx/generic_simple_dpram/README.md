This is a testbench to test and verify, the behavior of the generic_simple_dpram. Since, it depends on the generic values, there is the following test case, tested with the following generic values:
 
  - g_with_byte_enable           : false 
  - g_addr_conflict_resolution   : false
  - g_dual_clock                 : true

Two stimulus exist since there are two clock domains. OSVVM methodology is being used and randomized seed for the inputs. The testbench receives only random input and later (through assertion) it compares the output of the testbench with the one from RTL (there are two inputs but one output only). 
