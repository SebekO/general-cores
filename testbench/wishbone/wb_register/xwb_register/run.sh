#!/bin/bash -e

#This is a simple script to run simulations
#in GHDL

TB=tb_xwb_register

echo "Running simulation for $TB"

echo "  TEST CASE 1          "
echo "Wishbone Mode = CLASSIC"
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_WB_MODE=CLASSIC  
echo "*******************************************************************************"

echo "  TEST CASE 2            "
echo "Wishbone Mode = PIPELINED"
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_WB_MODE=PIPELINED  
echo "*******************************************************************************"

