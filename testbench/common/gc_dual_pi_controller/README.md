This is a testbench to verify the gc_dual_pi_controler core. It uses GHDL simulator and OSVVM as verification methodology. All input signals in the testbench are random, with random seed also. 

We can have this testbench running either for frequency mode, either for phase mode.
This can be changed, through a generic value in testbench "g_mode"

There is FSM coverage presented in the end of each run, to ensure that all legal states are covered. 
Self - Checking testbench, where RTL module's output is being compared with the one
calculated in the testbench with similar logic.

The other values in the rest of the generics are indicative and can be changed in
the run.sh script.
