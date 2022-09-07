#!/bin/bash -e
 
#This is a simple script to run simulations in GHDL
 
TB=tb_gc_prio_encoder
 
echo "Running simulation for $TB"
 
echo "Width = 1"
ghdl -r --std=08 -frelaxed-rules $TB  -gg_seed=$RANDOM -gg_width=1 
echo "********************************************************************************"

echo "Width = 3"
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_width=3 --wave=waveform.ghw
echo "********************************************************************************"

echo "Width = 7"
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_width=7
echo "********************************************************************************"

echo "Width = 16"
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_width=16
echo "********************************************************************************"

echo "Width = 31"
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_width=31
echo "********************************************************************************"

echo "Width = 128"
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_width=128
echo "********************************************************************************"

