This is a testbench for a simple delay line generator. It uses GHDL as a simulator.
The testing process is the following:
  - Assigning random input values (with random seed) using the OSVVM methodology.
  - Storing these values in a register and an array.
  - Via an assertion, comparing the testbench's output with the core's output, 
    to verify that the output is delayed as it is supposed to (regarding the `g_delay_cycles` generic value.


