#!/bin/bash -e

#This is a simple script to run simulations in GHDL

TB=tb_gc_negedge

echo "Running simulation for $TB"

echo "  TEST CASE 1                      "
echo "ASYNC_RST=TRUE, CLOCK_EDGE=positive"
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_ASYNC_RST=TRUE -gg_CLOCK_EDGE=positive 
echo "******************************************************************************************"

echo "  TEST CASE 2                      "
echo "ASYNC_RST=TRUE, CLOCK_EDGE=negative"
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_ASYNC_RST=TRUE -gg_CLOCK_EDGE=negative 
echo "******************************************************************************************"

echo "  TEST CASE 3                      "
echo "ASYNC_RST=FALSE, CLOCK_EDGE=positive"
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_ASYNC_RST=FALSE -gg_CLOCK_EDGE=positive
echo "******************************************************************************************"

echo "  TEST CASE 4                       "
echo "ASYNC_RST=FALSE, CLOCK_EDGE=negative"
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_ASYNC_RST=FALSE -gg_CLOCK_EDGE=negative
echo "******************************************************************************************"

