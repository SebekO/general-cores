#!/bin/bash -e

#This is a simple script to run simulations in GHDL

TB=tb_wb_i2c_bridge

echo "Running simulation for $TB"

ghdl -r --std=08 -frelaxed-rules $TB -gg_fsm_wdt=65535 --wave=waveform.ghw

