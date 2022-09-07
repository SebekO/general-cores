This is a simple testbench to verify the sdb_rom core. Because the rom and the values that has inside, can be changed, by changing the values of the generics, this testbench is very specific. It run for these specific values:

  - g_seed     : is the generic value used from OSVVM, to generate numbers with randomized seed
  - g_layout   : one array with all bits set to zero
  - g_bus_end  : all 64-bits set to '1'
  - g_wb_mode  : the wishbone interface mode has been set to CLASSIC
  - g_sdb_name : string which is specific, "WB4-Crossbar-GSI"

There are some test cases tested, depending on the number of masters. It can be 1, 2, 4 (or any other integer number).

What it is being tested in all cases is if the output slave has the correct data (from this non-generic ROM). In addition, it verifies that the slave has the correct values, as they supposed to be, regarding the specification (ERR, RTY, STALL, ACK) and they agree, with the ones generated from RTL core. 
