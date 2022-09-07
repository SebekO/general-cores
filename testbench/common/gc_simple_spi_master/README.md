This is a testbench to verify the gc_dual_pi_controler core. It uses GHDL simulator and OSVVM as verification methodology. All input signals in the testbench are random, with random seed also. There are two generics in the core:
  - g_div_ratio_log2 : Clock division ratio
  - g_num_data_bits  : Number of data bits per transfer

Regarding the assigned values in these generic, there can be various combinations (testcases), some of them are presented here (1,1), (2,2), (2,4), (3,4). 
The testbench, receives random input data (with random seeds). A clock divider counter generates s_tick which is used to control the FSM. One assertion exist in the testbench to bring self-checking capabilities in it and checks, if the incoming data is equal with the outcoming data, in the end of the FSM process.

FSM coverage is covered through the use of OSVVM methodology, where the transition of the states is being checked in every clock and the reports are shown in the end.  
