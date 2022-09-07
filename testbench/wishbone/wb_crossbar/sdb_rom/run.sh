#!/bin/bash -e

#This is a simple script to run simulations in GHDL

TB=tb_sdb_rom

echo "*******************************************************************************"
echo "Running simulation for $TB"

echo "*******************************************************************************"
echo "        TEST CASE 1 : number of masters = 1                                    "
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_masters=1  
echo "*******************************************************************************"

echo "*******************************************************************************"
echo "        TEST CASE 2 : number of masters = 2                                    "
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_masters=1  
echo "*******************************************************************************"

echo "*******************************************************************************"
echo "        TEST CASE 3 : number of masters = 4                                    "
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_masters=1  
echo "*******************************************************************************"

