This is a testbench to verify the gc_extend_pulse core. It uses GHDL simulator and OSVVM as verification methodology. All input signals in the testbench are random, with random seed also.

There are 4 test cases, depending on the width of the output pulse (2, 8, 12, 24). This can be extended more and have more test cases, but for simulation reasons it is preferred to give to the `g_width` generic, a lower value.

There are the following assertions, to give to the testbench a more self-checking approach:
  - Check that the duration of the output pulse (in clock cycles), is not bigger that g_width
  - Check that the output extended pulse is rising when input pulse is asserted

Simple coverage is being covered:
  - Reset has been asserted
  - Output pulse width is HIGH when input is HIGH
  - Output pulse de-asserted when reached the maximum width
