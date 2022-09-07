#!/bin/bash -e

#This is a simple script to run simulations in GHDL

TB=tb_gc_edge_detect

echo "Running simulation for $TB"

echo "      TEST CASE 1                                       "
echo "ASYNC_RST=TRUE, PULSE_EDGE=positive, CLOCK_EDGE=positive"
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_ASYNC_RST=TRUE -gg_PULSE_EDGE=positive -gg_CLOCK_EDGE=positive 
echo "*******************************************************************************************************"

echo "      TEST CASE 2                                       "
echo "ASYNC_RST=TRUE, PULSE_EDGE=positive, CLOCK_EDGE=negative"
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_ASYNC_RST=TRUE -gg_PULSE_EDGE=positive -gg_CLOCK_EDGE=negative 
echo "*******************************************************************************************************"

echo "      TEST CASE 3                                       "
echo "ASYNC_RST=TRUE, PULSE_EDGE=negative, CLOCK_EDGE=positive"
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_ASYNC_RST=TRUE -gg_PULSE_EDGE=negative -gg_CLOCK_EDGE=positive 
echo "*******************************************************************************************************"

echo "      TEST CASE 4                                       "
echo "ASYNC_RST=TRUE, PULSE_EDGE=negative, CLOCK_EDGE=negative"
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_ASYNC_RST=TRUE -gg_PULSE_EDGE=negative -gg_CLOCK_EDGE=negative 
echo "*******************************************************************************************************"

echo "      TEST CASE 5                                       "
echo "ASYNC_RST=FALSE, PULSE_EDGE=positive, CLOCK_EDGE=positive"
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_ASYNC_RST=FALSE -gg_PULSE_EDGE=positive -gg_CLOCK_EDGE=positive 
echo "*******************************************************************************************************"

echo "      TEST CASE 6                                       "
echo "ASYNC_RST=FALSE, PULSE_EDGE=positive, CLOCK_EDGE=negative"
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_ASYNC_RST=FALSE -gg_PULSE_EDGE=positive -gg_CLOCK_EDGE=negative 
echo "*******************************************************************************************************"

echo "      TEST CASE 7                                       "
echo "ASYNC_RST=FALSE, PULSE_EDGE=negative, CLOCK_EDGE=positive"
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_ASYNC_RST=FALSE -gg_PULSE_EDGE=negative -gg_CLOCK_EDGE=positive 
echo "*******************************************************************************************************"

echo "      TEST CASE 8                                       "
echo "ASYNC_RST=FALSE, PULSE_EDGE=negative, CLOCK_EDGE=negative"
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_ASYNC_RST=FALSE -gg_PULSE_EDGE=negative -gg_CLOCK_EDGE=negative 
echo "*******************************************************************************************************"
