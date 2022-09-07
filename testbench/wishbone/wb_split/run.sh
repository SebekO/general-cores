#!/bin/bash -e

#This is a simple script to run simulations
#in GHDL

TB=tb_xwb_split

echo "Running simulation for $TB"

echo "********************************************************************************"
echo "          TEST CASE:  MASK = all zeros"
echo "********************************************************************************"
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM  
echo "********************************************************************************"

