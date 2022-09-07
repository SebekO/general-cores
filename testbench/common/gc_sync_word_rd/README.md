1) the output signal: rd_in_o was open.

	For that reason, connect it with the d_ready signal in 
	the "gc_sync_word_rd.vhd", RTL file.

	==> this is a way to follow the assertion in gc_pulse_synchronizer2.vhd

2) As for the testing process:

	First of all, in every CLK_IN, if the rd_in_o (user-input side) is HIGH
	[rd_in_o: pulse when a data is transferred], we trigger a read (wishbone-out side) 
	which is the rd_out_i signal.

	Then, if this last signal is '1', we insert random data in the input. 

3) The self checking process:

	we compare the input and output value every time that ACK is HIGH.
	ack_out_o: pulse when the read is available (wishbone-out side)

The testbench uses OSVVM methodology with random seed used to generate
random input signals. Simple coverage is covered, when the resets have been
asserted properly.	
