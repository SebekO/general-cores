This is a testbench to verify the functionality of the xwb_clock_crossing. It is a cross clock domain wishbone adapter. It has been tested to use both for fast -> slow and slow -> fast clock domains. It contains 2 generic FIFOs (generic_async_fifo_dual_rst), one for Master (slave input to master output) and one for Slave (master input to slave output). 

The only generic that this core has, is the `g_size` which is then passed to the FIFOs. That means, that the generic values that the FIFOs have, can define the behavior of the core itself. 
