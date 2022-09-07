#!/bin/bash -e

#This is a simple script to run simulations in GHDL
 
TB=tb_gc_async_signals_input_stage

echo "******************************************************************************************"
echo "Running simulation for $TB"
echo "******************************************************************************************"

echo ""
echo "**************************TEST CASE 1 *****************************************************"
echo "Number of input signals = 1, extended clock cycles = 0, cycles that filter out glitches = 0"
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_signal_num=1 -gg_extended_pulse_width=0 -gg_dglitch_filter_len=0 
echo""

echo "**************************TEST CASE 2 *****************************************************"
echo "Number of input signals = 1, extended clock cycles = 0, cycles that filter out glitches = 1"
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_signal_num=1 -gg_extended_pulse_width=0 -gg_dglitch_filter_len=1
echo ""

echo "**************************TEST CASE 3 *****************************************************"
echo "Number of input signals = 2, extended clock cycles = 2, cycles that filter out glitches = 2"
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_signal_num=2 -gg_extended_pulse_width=2 -gg_dglitch_filter_len=2
echo ""

echo "**************************TEST CASE 4 *****************************************************"
echo "Number of input signals = 2, extended clock cycles = 2, cycles that filter out glitches = 4"
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_signal_num=2 -gg_extended_pulse_width=2 -gg_dglitch_filter_len=4
echo ""

echo "**************************TEST CASE 5 *****************************************************"
echo "Number of input signals = 4, extended clock cycles = 4, cycles that filter out glitches = 6"
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_signal_num=4 -gg_extended_pulse_width=4 -gg_dglitch_filter_len=6
echo ""

echo "**************************TEST CASE 6 *****************************************************"
echo "Number of input signals = 8, extended clock cycles = 8, cycles that filter out glitches = 10"
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_signal_num=8 -gg_extended_pulse_width=8 -gg_dglitch_filter_len=10
