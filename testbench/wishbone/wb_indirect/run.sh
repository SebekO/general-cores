#!/bin/bash -e

#This is a simple script to run simulations
#in GHDL

TB=tb_wb_indirect

echo "Running simulation for $TB"

echo "Mode = PIPELINED"
ghdl -r --std=08 -frelaxed-rules $TB
echo "*******************************************************************************"

