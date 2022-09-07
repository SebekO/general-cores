#!/bin/bash -e

#This is a simple script to run simulations
#in GHDL

TB=tb_gc_simple_spi_master

echo "Running simulation for $TB"
echo ""

echo "TEST CASE 1                                                   "
echo "Clock division ratio = 1, Number of data bits per transfer = 1"
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_div_ratio_log2=1 -gg_num_data_bits=1
echo "************************************************************************"

echo "TEST CASE 2                                                   "
echo "Clock division ratio = 2, Number of data bits per transfer = 2"
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_div_ratio_log2=2 -gg_num_data_bits=2
echo "************************************************************************"

echo "TEST CASE 3                                                   "
echo "Clock division ratio = 2, Number of data bits per transfer = 4"
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_div_ratio_log2=2 -gg_num_data_bits=4
echo "************************************************************************"

echo "TEST CASE 4                                                   "
echo "Clock division ratio = 3, Number of data bits per transfer = 4"
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_div_ratio_log2=3 -gg_num_data_bits=4
echo "************************************************************************"

