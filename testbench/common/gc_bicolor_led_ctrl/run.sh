#!/bin/bash -e

#This is a simple script to run simulations in GHDL
#In case we need to see waveforms, type --wave=waveform.ghw
#in the end of each command

TB=gc_bicolor_led_ctrl_tb

echo "Running simulation for $TB"

echo "********************  TEST CASE  **********************************"
echo "column=4, line=2, clock frequency in Hz=125000000, refresh rate=250"
ghdl -r --std=08 -frelaxed-rules $TB --stop-time=100ms
echo "*********************************************************************"

