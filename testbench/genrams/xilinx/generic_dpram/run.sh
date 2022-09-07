#!/bin/bash -e

#This is a simple script to run simulations in GHDL

TB=tb_generic_dpram

echo "Running simulation for $TB"

echo "Data width = 32 and size = 32"

#gen_dual_clock is going to be generated
echo "*******************************************************************************"
echo "        Test case 1: With byte enable = false                                  "
echo "                     Dual clock       = true,                                  "
echo "*******************************************************************************"
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed_a=$RANDOM -gg_seed_b=$RANDOM -gg_data_width=32 -gg_size=32 -gg_with_byte_enable=false -gg_dual_clock=true  

#gen_splitram is going to be generated
echo "*******************************************************************************"
echo "        Test case 2: With byte enable       = true                             "
echo "                     Dual clock             = false                            "
echo "*******************************************************************************"
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed_a=$RANDOM -gg_seed_b=$RANDOM -gg_data_width=32 -gg_size=32 -gg_with_byte_enable=true -gg_dual_clock=false  

#gen_dual_clk is going to be generated
echo "*******************************************************************************"
echo "        Test case 3: With byte enable       = true                             "
echo "                     Dual clock             = true                             "
echo "*******************************************************************************"
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed_a=$RANDOM -gg_seed_b=$RANDOM -gg_data_width=32 -gg_size=32 -gg_with_byte_enable=true -gg_dual_clock=true  

#gen_single_clock is going to be generated
echo "*******************************************************************************"
echo "        Test case 4: With byte enable       = false                            "
echo "                     Dual clock             = false                            "
echo "*******************************************************************************"
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed_a=$RANDOM -gg_seed_b=$RANDOM -gg_data_width=32 -gg_size=32 -gg_with_byte_enable=false -gg_dual_clock=false  


