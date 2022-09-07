#!/bin/bash -e
 
#This is a simple script to run simulations in GHDL

TB=tb_gc_reset_multi_aasd
 
echo "Running simulation for $TB"
echo ""

echo "  TEST CASE 1                          "
echo "Clock domains = 1, Number of resets = 2"
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_CLOCKS=1 -gg_RST_LEN=2
echo "****************************************************************************" 

echo "  TEST CASE 2                          "
echo "Clock domains = 1, Number of resets = 4"
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_CLOCKS=1 -gg_RST_LEN=4
echo "****************************************************************************" 

echo "  TEST CASE 3                          "
echo "Clock domains = 2, Number of resets = 2"
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_CLOCKS=2 -gg_RST_LEN=2 
echo "****************************************************************************" 

echo "  TEST CASE 4                          "
echo "Clock domains = 2, Number of resets = 4"
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_CLOCKS=2 -gg_RST_LEN=4 
echo "****************************************************************************" 

echo "  TEST CASE 5                          "
echo "Clock domains = 1, Number of resets = 1"
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_CLOCKS=1 -gg_RST_LEN=1

