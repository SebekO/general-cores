#!/bin/bash -e

#This is a simple script to run simulations in GHDL

TB=tb_gc_shiftreg

echo "Running simulation for $TB"


echo "*******************************************************************************"
echo "     Test case 1: Size of the shiftreg = 32                                "
echo "*******************************************************************************"
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_size=32 --wave=waveform.ghw 

