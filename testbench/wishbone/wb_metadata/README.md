Simple testbench for this little ROM which provides metadata for the "Convention". It uses OSVVM methodology and random inputs, based on random seed, are assigned in every clock cycle to the (input wishbone) signals. When the core is busy, and regarding of the value of the incoming address, the output data can receive a different value, as it is specified in the core's specifications.

Self-Checking: There are various assertions which can verify the proper functionality of the core by checking the value of the output wishbone data if it matches the expected one. 

