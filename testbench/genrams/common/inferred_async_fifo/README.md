This is a testbench to verify the functionality of the inferred_async_fifo. It is a dual clock (single reset) Asynchronous FIFO and can be used in two cases depending on the write and read clock. One case is when write clock is faster than the read clock and the other case is when the write clock is slower than the read clock. In addition, there are 6 different tests that can be simulated, regarding the values of the core's generics. Some of them remain stable throughout all the tests. These are:

  - `g_data_width`             : Data width set to 32-bits
  - `g_size`                   : Size is set to 32-bits
  - `g_with_wr_full`           : Full signal for write side is always true
  - `g_with_wr_empty`          : Empty signals for write sige is always true
  - `g_with_rd_empty`          : Empty signal for read side is always true
  - `g_with_rd_full`           : Full signal for read side is always true
  - `g_almost_empty_threshold` : Threshold for empty flag set to 2
  - `g_almost_full_threshold`  : Threshold for full signal set to 31

All the other generic values and the combination of them, create the 6 different test cases which are:

  - `g_show_ahead`           : true / false
  - `g_with_wr_almost_full`  : true / false
  - `g_with_wr_almost_empty` : true / false
  - `g_with_rd_almost_full`  : true / false
  - `g_with_rd_almost_empty` : true / false

NOTE: the option to have all of them as false would be a wrong option since, at least the full/empty signals are very important in the FIFO implementation and behavior.

OSVVM is used as the verification methodology. The inputs in the stimulus of the testbench are random with random seed for write and read side. In addition, these are the following assertions that exist in the testbench:

  - The FIFO is not full after reset
  - The FIFO is empty after reset
  - We don't write to the FIFO when it is full
  - We don't read from the FIFO when it is empty
  - The input (valid) data is the same as the output (valid) data
