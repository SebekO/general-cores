#!/bin/bash -e

#This is a simple script to run simulations in GHDL

TB=tb_gc_word_packer

echo "********************************************************************************************"
echo "Running simulation for $TB"
echo "********************************************************************************************"

echo ""
echo "       TEST CASE 1: Input width = 8  Output width = 8 "
echo ""
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_input_width=8 -gg_output_width=8

echo ""
echo "       TEST CASE 2: Input width = 8  Output width = 16 "
echo ""
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_input_width=8 -gg_output_width=16

echo ""
echo "       TEST CASE 3: Input width = 8  Output width = 128 "
echo ""
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_input_width=8 -gg_output_width=128

echo ""
echo "       TEST CASE 4: Input width = 16  Output width = 8 "
echo ""
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_input_width=16 -gg_output_width=8 

echo ""
echo "       TEST CASE 5: Input width = 64  Output width = 8 "
echo ""
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_input_width=64 -gg_output_width=8

echo ""
echo "       TEST CASE 6: Input width = 128  Output width = 32 "
echo ""
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_input_width=128 -gg_output_width=32



