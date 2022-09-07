#!/bin/bash -e

#This is a simple script to run simulations in GHDL

TB=tb_gc_glitch_filt

echo "Running simulation for $TB"

echo "TEST CASE 1                    "
echo "Length of the glitch filter = 1"
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_len=1
echo "*********************************************************"

echo "TEST CASE 2                    "
echo "Length of the glitch filter = 2"
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_len=2
echo "*********************************************************"

echo "TEST CASE 3                    "
echo "Length of the glitch filter = 8"
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_len=8
echo "*********************************************************"

echo "TEST CASE 4                     "
echo "Length of the glitch filter = 12"
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_len=12
echo "*********************************************************"
