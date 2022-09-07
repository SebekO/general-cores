Testbench for a wishbone slave adapter. It is using OSVVM methodology with all the  input signals in the stimulus to be get random values in each clock cycle. The simulation time, can be changed in the stim process, by changing the value of NOW. Regarding on the values that the generics of the core have, there are at least 8 test cases presented:

  - g_master_mode        : CLASSIC / PIPELINED
  - g_master_granularity :    WORD / BYTE
  - g_master_use_struct  :    TRUE / FALSE
  - g_slave_mode         : CLASSIC / PIPELINED
  - g_slave_granularity  :    WORD / BYTE
  - g_slave_struct       :    TRUE / FALSE

There are four different stimulus, for master and slave regarding of the value of the g_master_struct/g_slave_struct, all of them provide random values to the input signals.

Self-Checking: Various assertions are implemented in this testbench, to verify all the possible combinations and possibilities. They are categorized in `if..generate` statement blocks and test the correctness of the wishbone output signals.
