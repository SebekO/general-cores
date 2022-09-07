#!/bin/bash -e

#This is a simple script to run simulations
#in GHDL

TB=tb_xwb_async_bridge

echo "Running simulation for $TB"

echo "    TEST CASE 1                                                         "
echo "Simulation mode = ON, Address Granularity = WORD, CPU address width = 32"
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_simulation=1 -gg_address_granularity=WORD -gg_cpu_address_width=32 
echo "*******************************************************************************"

echo "    TEST CASE 2                                                         "
echo "Simulation mode = ON, Address Granularity = BYTE, CPU address width = 32"
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_simulation=1 -gg_address_granularity=BYTE -gg_cpu_address_width=32
echo "*******************************************************************************"

echo "    TEST CASE 3                                                          "
echo "Simulation mode = OFF, Address Granularity = WORD, CPU address width = 32"
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_simulation=0 -gg_address_granularity=WORD -gg_cpu_address_width=64 
echo "*******************************************************************************"

echo "    TEST CASE 4                                                          "
echo "Simulation mode = OFF, Address Granularity = BYTE, CPU address width = 32"
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_simulation=1 -gg_address_granularity=BYTE -gg_cpu_address_width=32
echo "*******************************************************************************"

