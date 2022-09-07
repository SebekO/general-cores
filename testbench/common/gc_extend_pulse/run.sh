#!/bin/bash -e

#This is a simple script to run simulations in GHDL

TB=tb_gc_extend_pulse

echo "Running simulation for $TB"

echo "TEST CASE 1            "
echo "Length of the pulse = 2"
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_width=2
echo "***********************************************************"

echo "TEST CASE 2            "
echo "Length of the pulse = 8"
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_width=8
echo "***********************************************************"

echo "TEST CASE 3             "
echo "Length of the pulse = 12"
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_width=12
echo "***********************************************************"

echo "TEST CASE 4             "
echo "Length of the pulse = 16"
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_width=16
echo "***********************************************************"

