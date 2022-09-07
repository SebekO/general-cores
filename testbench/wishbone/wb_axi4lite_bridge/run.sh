#!/bin/bash -e

#This is a simple script to run simulations
#in GHDL

TB=tb_xwb_axi4lite_bridge

echo "Running simulation for $TB"

ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM  
echo "*******************************************************************************"

