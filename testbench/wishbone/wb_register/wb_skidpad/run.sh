#!/bin/bash -e

#This is a simple script to run simulations in GHDL

TB=tb_wb_skidpad

echo "*******************************************************************************"
echo "Running simulation for $TB"

ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM 
echo "*******************************************************************************"


