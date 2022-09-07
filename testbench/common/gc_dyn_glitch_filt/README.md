Testbench to verify the functionality of the gc_dyn_glitch_filt general core. It receives randomized input signals with random seed. It consist of 3 test cases (can be extented to more) regarding the length of the latency. 

Some assertions are being used for better self-checking purposes. First of all, one of them, is checking that the glitch filter length is more than zero. Another assertion, is for the relation between input and output data. So, if input data, dat_i is HIGH, the output dat_o is HIGH after len_i clk cycles. The same goes in case the input data is LOW.

Simple coverage is being covered too, to better check that the testbench covers everything that needs to be checked. These cases are:
  - Reset has beend asserted
  - Output pulse is HIGH when input is HIGH
  - Output pulse is LOW when input is LOW

