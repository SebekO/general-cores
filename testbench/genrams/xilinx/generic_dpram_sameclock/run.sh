#!/bin/bash -e

#This is a simple script to run simulations
#in GHDL

TB=tb_generic_dpram_sameclock

echo "Running simulation for $TB"

echo "Data width = 32 and size = 64"

echo "Test case 1: No byte enable and no change in address conflict resolution"
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_data_width=32 -gg_size=64 -gg_with_byte_enable=false -gg_addr_conflict_resolution="no_change" 
echo "*******************************************************************************"

echo "Test case 2: With byte enable and write first in address conflict resolution"
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_data_width=32 -gg_size=64 -gg_with_byte_enable=true -gg_addr_conflict_resolution="write_first"
echo "*******************************************************************************"

echo "Test case 3: No byte enable and write first in address conflict resolution"
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_data_width=32 -gg_size=64 -gg_with_byte_enable=false -gg_addr_conflict_resolution="write_first"
echo "*******************************************************************************"

echo "Test case 4: No byte enable and Read first in address conflict resolution"
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_data_width=32 -gg_size=64 -gg_with_byte_enable=false -gg_addr_conflict_resolution="read_first" 
echo "*******************************************************************************"

echo "Test case 5: No byte enable and don't care what is the address conflict resolution"
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_data_width=32 -gg_size=64 -gg_with_byte_enable=false -gg_addr_conflict_resolution="dont_care"  
echo "*******************************************************************************"

echo "Test case 6: With byte enable and don't care what is the address conflict resolution"
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_data_width=32 -gg_size=64 -gg_with_byte_enable=true -gg_addr_conflict_resolution="dont_care"  
echo "*******************************************************************************"

echo "Test case 7: With byte enable and read first in address conflict resolution"
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_data_width=32 -gg_size=64 -gg_with_byte_enable=true -gg_addr_conflict_resolution="read_first"  
echo "*******************************************************************************"

