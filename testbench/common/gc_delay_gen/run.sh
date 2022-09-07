#!/bin/bash -e

#This is a simple script to run simulations in GHDL

TB=tb_gc_delay_gen

echo "Running simulation for $TB"

echo "************  TEST CASE 1  ***************"
echo "Number of delay cycles = 1, data width = 8"
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_delay_cycles=1 -gg_data_width=8

echo "************  TEST CASE 2  ***************"
echo "Number of delay cycles = 2, data width = 8"
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_delay_cycles=2 -gg_data_width=8

echo "************  TEST CASE 3  ***************"
echo "Number of delay cycles = 4, data width = 16"
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_delay_cycles=4 -gg_data_width=16

echo "************  TEST CASE 4  ***************"
echo "Number of inputs = 12, data width = 32"
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_delay_cycles=12 -gg_data_width=32


