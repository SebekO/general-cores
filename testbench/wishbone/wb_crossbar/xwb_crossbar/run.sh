#!/bin/bash -e

#This is a simple script to run simulations in GHDL

TB=tb_xwb_crossbar

echo "Running simulation for $TB"

echo "*******************************************************************************"
echo "                      TEST CASE 1                                              "
echo "  Number of masters = 2,  Number of slaves = 1                                 "
echo "  Registered = False   ,  Verbose = True                                       "
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_num_masters=2 -gg_num_slaves=1 -gg_registered=false -gg_verbose=true --wave=waveform.ghw 
echo "*******************************************************************************"

echo "*******************************************************************************"
echo "                      TEST CASE 2                                              "
echo "  Number of masters = 2,  Number of slaves = 1                                 "
echo "  Registered = False   ,  Verbose = False                                      "
#ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_num_masters=2 -gg_num_slaves=1 -gg_registered=false -gg_verbose=false --wave=waveform.ghw 
echo "*******************************************************************************"

echo "*******************************************************************************"
echo "                      TEST CASE 3                                              "
echo "  Number of masters = 2,  Number of slaves = 1                                 "
echo "  Registered = True    ,  Verbose = False                                      "
#ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_num_masters=2 -gg_num_slaves=1 -gg_registered=true -gg_verbose=false --wave=waveform.ghw 
echo "*******************************************************************************"

echo "*******************************************************************************"
echo "                      TEST CASE 4                                              "
echo "  Number of masters = 2,  Number of slaves = 1                                 "
echo "  Registered = True    ,  Verbose = True                                       "
#ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_num_masters=2 -gg_num_slaves=1 -gg_registered=true -gg_verbose=true --wave=waveform.ghw 
echo "*******************************************************************************"

