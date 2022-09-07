#!/bin/bash -e

#This is a simple script to run simulations in GHDL

TB=tb_gc_single_reset_gen

echo "Running simulation for $TB"
echo ""

echo "TEST CASE 1                                                                              "
echo "Number of FF's before the final reset signal = 1, number of input async reset signals = 1"
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_out_reg_depth=1 -gg_rst_in_num=1
echo "*****************************************************************************************"

echo "TEST CASE 2                                                                              "
echo "Number of FF's before the final reset signal = 2, number of input async reset signals = 2"
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_out_reg_depth=2 -gg_rst_in_num=2
echo "*****************************************************************************************"

echo "TEST CASE 3                                                                              "
echo "Number of FF's before the final reset signal = 4, number of input async reset signals = 5"
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_out_reg_depth=4 -gg_rst_in_num=5
echo "*****************************************************************************************"

echo "TEST CASE 4                                                                              "
echo "Number of FF's before the final reset signal = 2, number of input async reset signals = 8"
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_out_reg_depth=2 -gg_rst_in_num=8
echo "*****************************************************************************************"

