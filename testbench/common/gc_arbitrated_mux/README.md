This is a simple test which verify the functionality of the gc_arbitrated_mux. 
Various cases are being tested, regarding the number of inputs and the data width. 
In additions, assertions are being used to verify that the output that comes from
RTL core is the same as the one that the testbench has.

The testing process is:

  - Randomized inputs are given to the Design Under Test in order to check the functionality of the RTL core.
    For a given number of inputs, there are randomized inputs for a given data width.
  - A simple coverage metric, where counting the number of valid outputs.
  - An assertion is used to verify that the output and input data is the same.


