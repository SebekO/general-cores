#!/bin/bash -e
 
#This is a simple script to run simulations in GHDL

TB=tb_gc_i2c_slave

echo "Running simulation for $TB"

echo "******************************** TEST CASE 1 **************************************"
echo "Length of glitch filter = 0, automatically ACK reception upon address match = FALSE"
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$(($RANDOM%(2**31))) -gg_gf_len=0 -gg_auto_addr_ack=false 

echo "******************************** TEST CASE 2 **************************************"
echo "Length of glitch filter = 1, automatically ACK reception upon address match = TRUE"
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$(($RANDOM%(2**31))) -gg_gf_len=1 -gg_auto_addr_ack=true 
