#!/bin/bash -e

#This is a simple script to run simulations in GHDL
#In case we need to see waveforms, type --wave=waveform.ghw
#in the end of each command

TB=tb_gc_delay_line
echo "***********************************************************************"
echo "Running simulation for $TB"
echo "***********************************************************************"

echo "Number of delay cycles = 2, data width = 8"
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_delay=2 -gg_width=8
echo ""

echo "Number of delay cycles = 4, data width = 16"
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_delay=4 -gg_width=16
echo ""

echo "Number of inputs = 12, data width = 32"
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_delay=12 -gg_width=32
echo ""

