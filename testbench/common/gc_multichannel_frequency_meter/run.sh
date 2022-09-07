#!/bin/bash -e

#This is a simple script to run simulations in GHDL

TB=tb_gc_multichannel_frequency_meter

echo "Running simulation for $TB"

echo "======================================"
echo "*When g_WITH_INTERNAL_TIMEBASE = TRUE*"
echo "======================================"

echo "clk_sys_freq = 500, sync_out = TRUE, counter_bits=32"
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_WITH_INTERNAL_TIMEBASE=TRUE -gg_CLK_SYS_FREQ=500 -gg_CHANNELS=2 -gg_COUNTER_BITS=32 
echo "******************************************************************************"

echo "clk_sys_freq = 1000, sync_out = FALSE, counter_bits=32"
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_WITH_INTERNAL_TIMEBASE=TRUE -gg_CLK_SYS_FREQ=1000 -gg_CHANNELS=3 -gg_COUNTER_BITS=32
echo "******************************************************************************"

echo "clk_sys_freq = 5000, sync_out = TRUE, counter_bits=64"
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_WITH_INTERNAL_TIMEBASE=TRUE -gg_CLK_SYS_FREQ=5000 -gg_CHANNELS=4 -gg_COUNTER_BITS=32
echo "******************************************************************************"

echo "clk_sys_freq = 10000, sync_out = FALSE, counter_bits=8"
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_WITH_INTERNAL_TIMEBASE=TRUE -gg_CLK_SYS_FREQ=10000 -gg_CHANNELS=5 -gg_COUNTER_BITS=32
echo "******************************************************************************"

echo "======================================="
echo "*When g_WITH_INTERNAL_TIMEBASE = FALSE*"
echo "======================================="

echo "clk_sys_freq = 500, sync_out = TRUE, counter_bits=32"
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_WITH_INTERNAL_TIMEBASE=FALSE -gg_CLK_SYS_FREQ=500 -gg_CHANNELS=2 -gg_COUNTER_BITS=32
echo "******************************************************************************"

echo "clk_sys_freq = 1000, sync_out = FALSE, counter_bits=32"
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_WITH_INTERNAL_TIMEBASE=FALSE -gg_CLK_SYS_FREQ=1000 -gg_CHANNELS=3 -gg_COUNTER_BITS=32
echo "******************************************************************************"

echo "clk_sys_freq = 5000, sync_out = TRUE, counter_bits=64"
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_WITH_INTERNAL_TIMEBASE=FALSE -gg_CLK_SYS_FREQ=5000 -gg_CHANNELS=4 -gg_COUNTER_BITS=32
echo "******************************************************************************"

echo "clk_sys_freq = 10000, sync_out = FALSE, counter_bits=8"
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_WITH_INTERNAL_TIMEBASE=FALSE -gg_CLK_SYS_FREQ=10000 -gg_CHANNELS=5 -gg_COUNTER_BITS=32
echo "******************************************************************************"

