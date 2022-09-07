This is a testbench for gc_async_counter_diff. Various test cases are tested regarding
the counter width (in bits) and which is the output clock (either increment or decrement).
In the testbench there are two different stimulus, one for INC and one for DEC. We have 
two different clocks, so this test can be tested when: 
  1) clocks are same
  2) inc clock > dec clock
  3) inc clock < dec clock

The testing process is:
  - Assign a constant value of inc and dec clock. Then give random values to inc/dec valid 
    and check the output counter.
  - Some simple coverage metrics for example, to ensure that reset asserted


