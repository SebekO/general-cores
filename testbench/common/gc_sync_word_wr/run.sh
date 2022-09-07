#!/bin/bash -e
 
#This is a simple script to run simulations in GHDL

TB=tb_gc_sync_word_wr
 
echo "Running simulation for $TB"

echo "  TEST CASE 1  "
echo "AUTO_WR = TRUE "
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_AUTO_WR=TRUE 

echo "  TEST CASE 2  "
echo "AUTO_WR = FALSE"
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_AUTO_WR=FALSE 
 

