This test is divided in 6 test cases, depending on the value we assign to the generics. Mostly, the RTL core is being simulated for all possible values that `g_show_ahead` can take and also when almost_full and almost_empty logic signals are being used.

OSVVM methodology is used and random values assigned to the input in every clock cycle. Coverage is provided (the results can be showned in the end of the test, in the terminal). What is covered is:

  - Write while write side is empty
  - Write while write side is almost empty
  - Write while write side is almost full
  - Read while read side is full
  - Read while read side is almost empty
  - Read while read side is almost full

Simple VHDL assertions are used in order to verify that:

  - FIFO is not full after system reset
  - FIFO is empty after system reset
  - We don't write in a full FIFO
  - We don't read an empty FIFO

Self - checking part of the testbench includes the logic where we verify that the incoming data, matches with the outcoming data

NOTE: This core has been tested also for both cross clocking domains, when fast -> slow clock domain and vice versa
