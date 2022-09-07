This is a testbench to verufy the gc_shiftreg for Altera version. The core is a simple shift register which used in Altera designs.
All the inputs are random in every clock, with randomized seed. The verification methodology that being used is OSVVM. During the self-checking process, we compare the output of the testbench's logic with the RTL output.
