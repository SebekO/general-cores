The majority of the general cores has each own testbench written in VHDL and is using OSVVM as a verification methodology. Below, there are the requirements, that the user should fullfil, in order to run the tests locally:

  1. Install `HDLMAKE`, `GHDL` and `OSVVM(2020.05+)`
  2. Add in `usr/local/lib/ghdl/vendors/config.sh` the path of the downloaded OSVVM

There are two options for the user, in order to run these testbenches. One is to run them all through the Makefile that exist in this directory. This Makefile, contains all the tests, so with `make`, all the tests will run. The other option is to run a specific one seperately. For that option, these are the steps that need to be followed:

  1. Compile OSVVM by running the script: `/usr/local/lib/ghdl/vendors/compile-osvvm --all`
  2. Run `hdlmake makefile`
  3. Run `make`
  4. Run `./run.sh`
  5. (Optional) add in the run.sh --wave=waveform.ghw to see waveform with gtkwave
  6. See the results of the test in the terminal

