## Description
This is a testbench in order to verify the behavior of the axi4lite 32-bits to axi4full 64-bits, bridge [axi4lite32_axi4full64_bridge](../../modules/axi/axi4lite32_axi4full64_bridge/axi4lite32_axi4full64_bridge.vhd). Master is the axi4lite and the slave is axi4full.

NOTE: By default, the simulation time is 4ms. For any change in this, run the test and pass the simulation time as an argument to this script:
```console
./run.sh <simulation time>
```
