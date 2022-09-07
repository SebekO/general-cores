#!/bin/bash -e

#This is a simple script to run simulations in GHDL

TB=tb_xwb_clock_crossing

echo "Running simulation for $TB"

echo "************************************************************************"
echo "          TEST CASE 1:      size = 32                                   "
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_size=32 
echo "************************************************************************"

