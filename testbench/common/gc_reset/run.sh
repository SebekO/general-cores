#!/bin/bash -e

#This is a simple script to run simulations
#in GHDL

TB=tb_gc_reset

echo "Running simulation for $TB"
echo ""

echo "  TEST CASE 1                                     "
echo "Number of clocks = 1, LogDelay = 1 , SyncDepth = 1"
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_clocks=1 -gg_logdelay=1 -gg_syncdepth=1
echo "****************************************************************************"

echo "  TEST CASE 2                                     "
echo "Number of clocks = 2, LogDelay = 2 , SyncDepth = 2"
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_clocks=2 -gg_logdelay=2 -gg_syncdepth=2
echo "****************************************************************************"

echo "  TEST CASE 3                                     "
echo "Number of clocks = 1, LogDelay = 5 , SyncDepth = 3"
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_clocks=1 -gg_logdelay=3 -gg_syncdepth=4
echo "****************************************************************************"

echo "  TEST CASE 4                                     "
echo "Number of clocks = 4, LogDelay = 3, SyncDepth = 4"
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_clocks=4 -gg_logdelay=4 -gg_syncdepth=4
echo "****************************************************************************"



