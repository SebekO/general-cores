#!/bin/bash
 
#This is a simple script to run simulations in GHDL
 
TB=tb_gc_pulse_synchronizer2
 
echo "Running simulation for $TB"
 
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM --wave=waveform.ghw
