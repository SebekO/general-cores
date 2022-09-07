#!/bin/bash -e

#This is a simple script to run simulations
#in GHDL

TB=tb_gc_serial_dac

echo "Running simulation for $TB"

echo "TEST CASE 1"
echo "DAC data word bits = 2, Padding MSBs sent as zeros= 0, chip select inputs = 1, Serial clock polarity = 0"
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_num_data_bits=2 -gg_num_extra_bits=0 -gg_num_cs_select=1 -gg_sclk_polarity=0
echo "**********************************************************************************************************"

echo "TEST CASE 2"
echo "DAC data word bits = 2, Padding MSBs sent as zeros= 1, chip select inputs = 2, Serial clock polarity = 0"
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_num_data_bits=2 -gg_num_extra_bits=1 -gg_num_cs_select=2 -gg_sclk_polarity=0
echo "**********************************************************************************************************"

echo "TEST CASE 3"
echo "DAC data word bits = 4, Padding MSBs sent as zeros= 4, chip select inputs = 2, Serial clock polarity = 0"
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_num_data_bits=4 -gg_num_extra_bits=4 -gg_num_cs_select=2 -gg_sclk_polarity=0
echo "**********************************************************************************************************"

echo "TEST CASE 4"
echo "DAC data word bits = 16, Padding MSBs sent as zeros= 8, chip select inputs = 1, Serial clock polarity = 0"
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_num_data_bits=16 -gg_num_extra_bits=8 -gg_num_cs_select=1 -gg_sclk_polarity=0
echo "**********************************************************************************************************"

echo "TEST CASE 5"
echo "DAC data word bits = 2, Padding MSBs sent as zeros= 0, chip select inputs = 1, Serial clock polarity = 1"
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_num_data_bits=2 -gg_num_extra_bits=0 -gg_num_cs_select=1 -gg_sclk_polarity=1
echo "**********************************************************************************************************"

echo "TEST CASE 6"
echo "DAC data word bits = 4, Padding MSBs sent as zeros= 2, chip select inputs = 1, Serial clock polarity = 1"
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_num_data_bits=4 -gg_num_extra_bits=2 -gg_num_cs_select=1 -gg_sclk_polarity=1
echo "**********************************************************************************************************"

echo "TEST CASE 7"
echo "DAC data word bits = 8, Padding MSBs sent as zeros= 4, chip select inputs = 2, Serial clock polarity = 1"
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_num_data_bits=8 -gg_num_extra_bits=4 -gg_num_cs_select=2 -gg_sclk_polarity=1
echo "**********************************************************************************************************"

echo "TEST CASE 8"
echo "DAC data word bits = 16, Padding MSBs sent as zeros= 8, chip select inputs = 2, Serial clock polarity = 1"
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_num_data_bits=16 -gg_num_extra_bits=8 -gg_num_cs_select=2 -gg_sclk_polarity=1
echo "**********************************************************************************************************"
