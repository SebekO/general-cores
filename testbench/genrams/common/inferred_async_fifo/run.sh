#!/bin/bash -e

#This is a simple script to run simulations
#in GHDL

TB=tb_inferred_async_fifo

echo "Running simulation for $TB"

echo "Data width = 32 and size = 32"

echo "*******************************************************************************"
echo "     Test case 1: Show ahead = TRUE                                "
echo "                  With almost empty and almost full logic for WR/RD"
echo "*******************************************************************************"
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed_wr=$RANDOM -gg_seed_rd=$RANDOM -gg_data_width=32 -gg_size=32 -gg_show_ahead=true -gg_with_rd_empty=true -gg_with_rd_full=true -gg_with_rd_almost_empty=true -gg_with_rd_almost_full=true -gg_with_wr_empty=true -gg_with_wr_full=true -gg_with_wr_almost_full=true -gg_with_wr_almost_empty=true -gg_almost_empty_threshold=2 -gg_almost_full_threshold=31 

echo "*******************************************************************************"
echo "     Test case 2: Show ahead = TRUE                                "
echo "                  NO almost empty and almost full logic for WR/RD"
echo "*******************************************************************************"
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed_wr=$RANDOM -gg_seed_rd=$RANDOM -gg_data_width=32 -gg_size=32 -gg_show_ahead=true -gg_with_rd_empty=true -gg_with_rd_full=true -gg_with_rd_almost_empty=false -gg_with_rd_almost_full=false -gg_with_wr_empty=true -gg_with_wr_full=true -gg_with_wr_almost_full=false -gg_with_wr_almost_empty=false -gg_almost_empty_threshold=2 -gg_almost_full_threshold=31

echo "*******************************************************************************"
echo "     Test case 3: Show ahead = FALSE                               "
echo "                  With almost empty and almost full logic for WR/RD"
echo "*******************************************************************************"
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed_wr=$RANDOM -gg_seed_rd=$RANDOM -gg_data_width=32 -gg_size=32 -gg_show_ahead=false -gg_with_rd_empty=true -gg_with_rd_full=true -gg_with_rd_almost_empty=true -gg_with_rd_almost_full=true -gg_with_wr_empty=true -gg_with_wr_full=true -gg_with_wr_almost_full=true -gg_with_wr_almost_empty=true -gg_almost_empty_threshold=2 -gg_almost_full_threshold=31 --wave=waveform.ghw

echo "*******************************************************************************"
echo "     Test case 4: Show ahead = FALSE                                "
echo "                  NO almost empty and almost full logic for WR/RD"
echo "*******************************************************************************"
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed_wr=$RANDOM -gg_seed_rd=$RANDOM -gg_data_width=32 -gg_size=32 -gg_show_ahead=true -gg_with_rd_empty=true -gg_with_rd_full=true -gg_with_rd_almost_empty=false -gg_with_rd_almost_full=false -gg_with_wr_empty=true -gg_with_wr_full=true -gg_with_wr_almost_full=false -gg_with_wr_almost_empty=false -gg_almost_empty_threshold=2 -gg_almost_full_threshold=31 

echo "*******************************************************************************"
echo "     Test case 5: Show ahead = TRUE                          "
echo "                With almost empty and almost full logic for WR"
echo "                  NO almost empty and almost full logic for RD"
echo "*******************************************************************************"
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed_wr=$RANDOM -gg_seed_rd=$RANDOM -gg_data_width=32 -gg_size=32 -gg_show_ahead=true -gg_with_rd_empty=true -gg_with_rd_full=true -gg_with_rd_almost_empty=false -gg_with_rd_almost_full=false -gg_with_wr_empty=true -gg_with_wr_full=true -gg_with_wr_almost_full=true -gg_with_wr_almost_empty=true -gg_almost_empty_threshold=2 -gg_almost_full_threshold=31

echo "*******************************************************************************"
echo "     Test case 6: Show ahead = TRUE                          "
echo "                With almost empty and almost full logic for RD"
echo "                  NO almost empty and almost full logic for WR"
echo "*******************************************************************************"
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed_wr=$RANDOM -gg_seed_rd=$RANDOM -gg_data_width=32 -gg_size=32 -gg_show_ahead=true -gg_with_rd_empty=true -gg_with_rd_full=true -gg_with_rd_almost_empty=true -gg_with_rd_almost_full=true -gg_with_wr_empty=true -gg_with_wr_full=true -gg_with_wr_almost_full=false -gg_with_wr_almost_empty=false -gg_almost_empty_threshold=2 -gg_almost_full_threshold=31 
