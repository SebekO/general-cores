#!/bin/bash -e

#This is a simple script to run simulations
#in GHDL

TB=tb_generic_spram

echo "Running simulation for $TB"

echo "      TEST CASE 1                                                                        "
echo "Data width = 32, size = 1024, Byte enable = FALSE, Addr conflict resolution = write_first"
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_data_width=32 -gg_size=1024 -gg_with_byte_enable=false -gg_addr_conflict_resolution="write_first"
echo "*******************************************************************************"

echo "      TEST CASE 2                                                                       "
echo "Data width = 32, size = 1024, Byte enable = FALSE, Addr conflict resolution = read_first"
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_data_width=32 -gg_size=1024 -gg_with_byte_enable=false -gg_addr_conflict_resolution="read_first" 
echo "*******************************************************************************"

echo "      TEST CASE 3                                                                      "
echo "Data width = 32, size = 512, Byte enable = TRUE, Addr conflict resolution = write_first"
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_data_width=32 -gg_size=512 -gg_with_byte_enable=true -gg_addr_conflict_resolution="write_first" 
echo "*******************************************************************************"

echo "      TEST CASE 4                                                                     "
echo "Data width = 32, size = 512, Byte enable = TRUE, Addr conflict resolution = read_first"
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_data_width=32 -gg_size=512 -gg_with_byte_enable=true -gg_addr_conflict_resolution="read_first" 
echo "*******************************************************************************"

