#!/bin/bash -e
 
#This is a simple script to run simulations in GHDL
 
TB=tb_gc_rr_arbiter
 
echo "Running simulation for $TB"
 
echo "Width = 1"
ghdl -r --std=08 -frelaxed-rules $TB -gg_size=1 -gg_seed=$RANDOM
echo "********************************************************************************"

echo "Width = 3"
ghdl -r --std=08 -frelaxed-rules $TB -gg_size=3 -gg_seed=$RANDOM
echo "********************************************************************************"

echo "Width = 7"
ghdl -r --std=08 -frelaxed-rules $TB -gg_size=7 -gg_seed=$RANDOM
echo "********************************************************************************"

echo "Width = 16"
ghdl -r --std=08 -frelaxed-rules $TB -gg_size=16 -gg_seed=$RANDOM
echo "********************************************************************************"

echo "Width = 31"
ghdl -r --std=08 -frelaxed-rules $TB -gg_size=31 -gg_seed=$RANDOM
echo "********************************************************************************"

echo "Width = 128"
ghdl -r --std=08 -frelaxed-rules $TB -gg_size=128 -gg_seed=$RANDOM
echo "********************************************************************************"

