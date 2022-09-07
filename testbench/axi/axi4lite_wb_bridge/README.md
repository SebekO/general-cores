This is the testbench for the axi4lite to wishbone bridge (axi4lite_wb_bridge).
GHDL used as a simulator alongside with OSVVM methodology. The testing process is:

  - Randomized inputs are given to the Design Under Test in order to check the 
    functionality of the RTL core. 
  - FSM coverage. Legal and ilegal state changes are printed in the end.
  - Assertions are used to check that the protocols of AXI-Lite and Wishbone
    behave as it is expected.

How to run the test:
  1) For this test you need to install HDLMAKE, GHDL and OSVVM(2020.05+)
  2) Add in  `usr/local/lib/ghdl/vendors/config.sh` the path of the OSVVM
  3) Compile OSVVM by running the script:
      /usr/local/lib/ghdl/vendors/compile-osvvm --all
  4) run `hdlmake makefile`
  5) run `make`
  6) run `./run.sh`
  7) (Optional) add in the `run.sh` --wave=waveform.ghw to see waveform
     with gtkwave
  8) See the results of the test
