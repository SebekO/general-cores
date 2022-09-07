Testbench for AXI4Lite-to-WB bridge wrapper. It is using OSVVM methodology with all the  input signals in the stimulus to be get random values in each clock cycle. The simulation time, can be changed in the `stim` process, by changing the value of `NOW`. There is only one test case and actually, test the functionality of this bridge core, through FSM coverage and assertions.

FSM coverage: In the RTL core, there is a FSM where it describes the behavior of the bridge. This testbench, covers all the possible changes of the states and also investigate if there are illigal transitions through the states. The goal is to reach 100% and all states covered at least once. The checking is done in every clock cycle, so when the state remains the some for some clock cycles is also covered. 

Self-Checking: Assertions are massively used in order to verify the correctness of the  functionality of Wishbone and AXI4-lite protocols. All of them are taken from the specification of these protocols. 
