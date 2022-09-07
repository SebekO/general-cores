#!/bin/bash -e

#This is a simple script to run simulations
#in GHDL

TB=tb_xwb_metadata

echo "Running simulation for $TB"

echo "This test is running with seed = 123456789"
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM --wave=waveform.ghw
echo "*******************************************************************************"

