This is a testbench to verify the functionality of inferred_sync_fifo core. It is a single clock/reset FIFO which is using the generic_dpram (with single clock functionality). Depending on the values of the generics there are 5 test cases that are being tested. The stable generics are:

  - `g_data_width`            : 32-bits
  - `g_size`                  : 32
  - `g_show_ahead`            : true
  - `g_with_full`             : true
  - `g_with_empty`            : true
  - `g_almost_full_threshold` : 0
  - `g_almost_empty_threshold`: 0

So, the test cases of the testbench are a combination of the rest of the generics:

  - `g_show_ahead_legacy_mode`  : true / false
  - `g_register_flag_outputs`   : true / false  
  - `g_with_almost_full`        : true / false  (threshold for almost full  flag)
  - `g_with_almost_empty`       : true / false  (threshold for almost empty flag)
  - `g_with_count`              : true / false  (words counter)

OSVVM is used as the verification methodology. The inputs in the stimulus of the testbench are random with random seed. In addition, these are the following assertions that exist in the testbench:

  - The FIFO is not full after reset
  - The FIFO is empty after reset
  - We don't write to the FIFO when it is full
  - We don't read from the FIFO when it is empty
  - The input (valid) data is the same as the output (valid) data

In addition, some simple coverage analysis is taken into account in every test case:

  - Write while FIFO is empty
  - Write while FIFO is almost empty
  - Write while FIFO is almost full
  - Read while FIFO is full
  - Read while FIFO is almost empty
  - Read while FIFO is almost full

NOTE: In some of the test cases, it is possible that some of them would be 0. This is happening because in some of them for example, the almost empty/full flags are not used.
