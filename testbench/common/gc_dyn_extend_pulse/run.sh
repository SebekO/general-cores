#!/bin/bash -e

#This is a simple script to run simulations
#in GHDL

TB=tb_gc_dyn_extend_pulse

echo "Running simulation for $TB"

echo "    TEST CASE 1"
echo "Length of the pulse = 2"
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_len_width=2
echo "***************************************************************"

echo "    TEST CASE 2"
echo "Length of the pulse = 4"
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_len_width=4 --wave=waveform.ghw
echo "***************************************************************"

echo "    TEST CASE 3"
echo "Length of the pulse = 6"
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_len_width=6
echo "***************************************************************"

