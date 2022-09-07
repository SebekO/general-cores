#!/bin/bash -e

#This is a simple script to run simulations in GHDL

TB=tb_gc_async_counter_diff

echo "Running simulation for $TB"

echo "**************************************************"
echo "              TEST CASE 1                         "
echo "Number of counter widdth = 1, g_output_clock = inc"
echo "**************************************************"
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_bits=1 -gg_output_clock="inc"

echo "**************************************************"
echo "              TEST CASE 2                         "
echo "Number of counter widdth = 4, g_output_clock = inc"
echo "**************************************************"
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_bits=4 -gg_output_clock="inc"

echo "**************************************************"
echo "              TEST CASE 3                         "
echo "Number of counter widdth = 8, g_output_clock = inc"
echo "**************************************************"
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_bits=8 -gg_output_clock="inc"

echo "**************************************************"
echo "              TEST CASE 4                         "
echo "Number of counter widdth = 15, g_output_clock = inc"
echo "**************************************************"
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_bits=15 -gg_output_clock="inc"

echo "**************************************************"
echo "              TEST CASE 5                         "
echo "Number of counter widdth = 1, g_output_clock = dec"
echo "**************************************************"
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_bits=1 -gg_output_clock="dec"

echo "**************************************************"
echo "              TEST CASE 6                         "
echo "Number of counter widdth = 4, g_output_clock = dec"
echo "**************************************************"
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_bits=4 -gg_output_clock="dec"

echo "**************************************************"
echo "              TEST CASE 7                         "
echo "Number of counter widdth = 8, g_output_clock = dec"
echo "**************************************************"
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_bits=8 -gg_output_clock="dec"

echo "**************************************************"
echo "              TEST CASE 8                         "
echo "Number of counter widdth = 15, g_output_clock = dec"
echo "**************************************************"
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_bits=15 -gg_output_clock="dec"


