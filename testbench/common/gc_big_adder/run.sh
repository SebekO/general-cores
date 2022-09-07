#!/bin/bash -e

#This is a simple script to run simulations in GHDL
#In case we need to see waveforms, type --wave=waveform.ghw
#in the end of each command

TB=tb_gc_big_adder

echo "Running simulation for $TB"

echo "data bits = 64, g_parts = 4"
ghdl -r --std=08 -frelaxed-rules $TB -gg_data_bits=64 -gg_parts=4
echo "***********************************************************"

echo "data bits = 32, g_parts = 2"
ghdl -r --std=08 -frelaxed-rules $TB -gg_data_bits=32 -gg_parts=2
echo "***********************************************************"

echo "data bits = 16, g_parts = 4"
ghdl -r --std=08 -frelaxed-rules $TB -gg_data_bits=16 -gg_parts=4
echo "***********************************************************"

echo "data bits = 8, g_parts = 1"
ghdl -r --std=08 -frelaxed-rules $TB -gg_data_bits=8 -gg_parts=1
echo "***********************************************************"



