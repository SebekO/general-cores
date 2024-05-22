# Testbench for [gc_edge_detect](../../../modules/common/gc_edge_detect.vhd) common core

## Requirements for Linux
1. Install [VUnit](https://vunit.github.io/installing.html).
2. Install [GHDL](https://github.com/ghdl/ghdl/releases). Note that GHDL with GCC backend is required for code coverage. For Ubuntu 20.04 it works with gcc 9.4.

## Testbench description
The testbench is running using VUnit and it uses OSVVM for randomization of the inputs and for basic coverage. It checks the width of the ouput pulse, depending on the given generics in the beginning of the simulation. It also verifys if the the output pulse is high in the falling or in the rising edge of the input pulse.

The generics of this core are the following:
  | Generics     |    Type    |  Values         |
  |--------------|:----------:|----------------:|
  | g_async_rst  | Boolean    | True/False      |   
  | g_pulse_edge | String     |Positive/Negative|
  | g_clock_edge | String     |Positive/Negative|

Regarding on the values of the above generics and their combinations, there are 8 different test cases.

## How to run the testbench

This testbench has been tested using GHDL and Aldec Riviera Pro. VUnit will select the simulator based on the specified `$PATH`. So the same commands are used to run the testbench, regardless the simulator.
```
python3 run.py -v
```

Note: Each testbench using a common python module `sim_utils.py` which includes various functions.
## Basic information for VUnit
1. Basic arguments for VUnit `python3 run.py`
  - `--list` for viewing the list of the tests
  - `-v` for verbode run
  - `--gtkwave-fmt=(vcd,ghw)` for generating a waveform file (only when using GHDL)
  - `-g <name of the test>` for opening in GUI the running test
2. Each testbench requires a `run.py` file 

