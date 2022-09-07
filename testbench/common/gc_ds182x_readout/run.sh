#!/bin/bash -e

#This is a simple script to run simulations in GHDL

TB=gc_ds182x_readout_tb

echo "Running simulation for $TB"

echo "********************************************************"
echo "                    TEST CASE                           "
echo "Clock frequency (kHz) = 40.000, Use internal pps = false"
echo "********************************************************"
ghdl -r --std=08 -frelaxed-rules $TB --stop-time=600ms
