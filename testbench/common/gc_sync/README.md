Testbench to verify the functionality of gc_sync general core. It uses GHDL simulator and OSVVM verification methodology. Through the `g_sync_edge` there is an option of working for positive or negative clock edge. Due to that, there can be two test cases. The value of the input signal, is random with random seed in every run. This can be achieved from OSVVM methodology as well. 

One assertion exist in the testbench in order to provide a more self-checking approach. It checks if the output is asserted (or de-asserted in falling edge of the clock), after 2 clock cycles.


