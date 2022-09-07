#!/bin/bash -e

#This is a simple script to run simulations in GHDL

TB=tb_gc_arbitrated_mux

echo "Running simulation for $TB"

echo "************************************"
echo "      TEST CASE 1                   "
echo "Number of inputs = 1, data width = 1"
echo "************************************"
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_num_inputs=1 -gg_width=1

echo "************************************"
echo "      TEST CASE 2                   "
echo "Number of inputs = 2, data width = 2"
echo "************************************"
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_num_inputs=2 -gg_width=2

echo "************************************"
echo "      TEST CASE 3                   "
echo "Number of inputs = 2, data width = 8"
echo "************************************"
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_num_inputs=2 -gg_width=8

echo "*************************************"
echo "      TEST CASE 4                    "
echo "Number of inputs = 8, data width = 32"
echo "*************************************"
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_num_inputs=8 -gg_width=32


