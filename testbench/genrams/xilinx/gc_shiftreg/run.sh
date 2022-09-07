#!/bin/bash -e

#This is a simple script to run simulations
#in GHDL

TB=tb_gc_shiftreg

echo "Running simulation for $TB"

echo "Test case 1: Size = 64 bits"
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_size=64  
echo "***********************************************************"

echo "Test case 2: Size = 128 bits"
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_size=128 
echo "***********************************************************"


