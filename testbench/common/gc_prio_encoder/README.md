Testbench to verify the functionality of the gc_prio_encoder general core. It receives randomized input signals with random seed. It consist of 6 test cases (can be extented to more) regarding the incoming data width. These test cases are:
  1. g_width = 1
  2. g_width = 3
  3. g_width = 7
  4. g_width = 16
  5. g_width = 31
  6. g_width = 128

This testbench is using the simple logic of the priority encoder, like in the RTL code. The result is stored in a vector and then it is being compared with the one which coming from the RTL core. 

Assertions are being used for better self-checking purposes. First of all, it checks if there is a mismatch between the output data of the testbench and RTL code. In addition, the other assertion, checks if the generic value is valid (should be 1 or higher).
