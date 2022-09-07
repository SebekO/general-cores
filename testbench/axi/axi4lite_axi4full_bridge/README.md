This is a testbench in order to verify the behavior of the axi4lite to axi4full
bridge. Master is the axi4lite and the slave is axi4full.

For the development of the RTL core and the testbench, the documentation that
taken into account is : "AMBA AXI and ACE Protocol Specification". OSVVM used
as verification methodology and GHDL is the simulator.

NOTE: You can change the simulation time by changing the NOW variable in the stimulus
      Also, add in the *run.sh* the --wave=waveform.ghw option in order to generate waveform
      file through GHDL simulator.

The testing process is the following:
  - Randomized values are given to the Design Under Test input signals.
  - FSM coverage. Legal and ilegal states are printed in the end of the simulation.
  - Assertions are used to check the functionality of the AXI4-Full and AXI4-Lite protocols

How to run the test:

  1) For this test you need to install HDLMAKE, GHDL and OSVVM(2020.05+)
  2) Add in usr/local/lib/ghdl/vendors/config.sh the path of the OSVVM
  3) Compile OSVVM by running the script: `/usr/local/lib/ghdl/vendors/compile-osvvm --all`
  4) run hdlmake makefile
  5) run make
  6) run ./run.sh
  7) (Optional) add in the run.sh --wave=waveform.ghw to see waveform with gtkwave
  8) See the results of the test

