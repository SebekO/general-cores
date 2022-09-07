This is a generic testbench which checks the width of the ouput pulse, depending on the given generics in the beginning of the simulation. The output pulse is high in the falling or in the rising edge of the input pulse.

The generics of this core are the following:
  - g_async_rst  : Synchronous or asynchronous reset
  - g_pulse_edge : Detect of positive or negative edges
  - g_clock_edge : Clock edge sensitivity of edge detection

Regarding on the values of the above generics, there are the following test cases:
	1. TRUE, positive, positive
	2. TRUE, positive, negative
	3. TRUE, negative, negative
	4. TRUE, negative, negative
	5. FALSE, positive, positive
	6. FALSE, positive, negative
	7. FALSE, negative, positive
	8. FALSE, negative, negative

The testbench is using OSVVM for randomization of the inputs and for basic coverage. Simple assertions are using, to verify that the output is the same as the input, after one clock.
