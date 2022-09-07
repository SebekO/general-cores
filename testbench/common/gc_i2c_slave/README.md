This is a testbech to test the gc_i2c_slave general core. The specification that the core is based on
is: https://www.csd.uoc.gr/~hy428/reading/i2c_spec.pdf

The testing process is the following:

  - Assigning a standard i2c address and scl, sda input signals in order to verify the functionality
    of the core, as it is described in the specification.
  - FSM coverage can be shown in the end of the simulation, using the OSVVM methodology and GHDL as simulator 
    (due to that we are giving standard input values through procedures and not random values, the coverage
     results are expected to be the same in every run).
  - Assertions are used to verify the write and read process.

