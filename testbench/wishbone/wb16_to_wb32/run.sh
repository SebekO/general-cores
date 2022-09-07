#!/bin/bash -e

#This is a simple script to run simulations
#in GHDL

TB=tb_wb16_to_wb32

echo "Running simulation for $TB"

echo "Mode = PIPELINED"
ghdl -r --std=08 -frelaxed-rules $TB 
echo "*******************************************************************************"


