The basic idea of this test is:

	either gc_SYNC_EDGE is positive or negative,
	we need ppulse_o to catch the positive edge
	npulse_o to catch the negative pulse
	of the synced_o.

	synced_o is data_i but synchronized.
	
	we need 2 clocks because of gc_sync and
	1 clock because of gc_sync_ffs, so the output 
	is the delayed by 3 clocks, input

OSVVM methodology is used and there is one assertion
to verify that the output pulse is synchronized as it 
is expected. Very simple coverage is used to check 
the behavior of reset. 
