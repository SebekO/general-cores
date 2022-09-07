#!/bin/bash -e

#This is a simple script to run simulations
#in GHDL

TB=tb_gc_sync_ffs

echo "Running simulation for $TB"

echo "SYNC_EDGE=positive"
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_SYNC_EDGE=positive

echo "SYNC_EDGE=negative"
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_SYNC_EDGE=negative

