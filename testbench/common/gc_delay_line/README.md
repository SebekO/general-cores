This is a testbench to verify that gc_delay_line core is working properly.
It uses GHDL as a simulator and OSVVM verification methodology. The testing process is the following:

  - Assigning random input values (with random seed) using the OSVVM methodology.
  - Storing these values in a register and an array.
  - An assertion is used in order to compare the output of the testbench and the output of the 
    core. In this way, the functionality is being tested. 
  - In `run.sh`, which is the script to run the simulation, the value of the generics can be 
    changed and run the test with more test cases.

