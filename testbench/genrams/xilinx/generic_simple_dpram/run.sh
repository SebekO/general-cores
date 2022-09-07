#!/bin/bash -e

#This is a simple script to run simulations in GHDL

TB=tb_generic_simple_dpram

echo "Running simulation for $TB"

echo "Data width = 32 and size = 64"

echo "*******************************************************************************"
echo "Test case 1: With byte enable         = false                                  "
echo "             Addr conflict resolution = false                                  "
echo "             Dual clock               = true                                   "
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed_a=$RANDOM -gg_seed_b=$RANDOM -gg_data_width=32 -gg_size=64 -gg_with_byte_enable=false 
echo "*******************************************************************************"
