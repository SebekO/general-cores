#!/bin/bash -e

#This is a simple script to run simulations
#in GHDL

TB=tb_gc_fsm_watchdog

echo "Running simulation for $TB"

echo "  TEST CASE 1              "
echo "Value of watchdog timer = 1"
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_wdt_max=1
echo "*************************************************************"

echo "  TEST CASE 2              "
echo "Value of watchdog timer = 2"
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_wdt_max=2
echo "*************************************************************"

echo "  TEST CASE 3              "
echo "Value of watchdog timer = 4"
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_wdt_max=4
echo "*************************************************************"

echo "  TEST CASE 4              "
echo "Value of watchdog timer = 8"
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_wdt_max=8
echo "*************************************************************"

