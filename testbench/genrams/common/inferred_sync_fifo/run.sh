#!/bin/bash -e

#This is a simple script to run simulations
#in GHDL

TB=tb_inferred_sync_fifo

echo "Running simulation for $TB"

echo "Data width = 32 and size = 32"

echo "*******************************************************************************"
echo "        Test case 1: Show ahead = TRUE, Show ahead legacy mode = TRUE"
echo "                     Register flag outputs = TRUE,                   "
echo "                  With no almost empty and almost full logic         "
echo "*******************************************************************************"
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_data_width=32 -gg_size=32 -gg_show_ahead=true -gg_show_ahead_legacy_mode=true -gg_register_flag_outputs=true --wave=waveform.ghw 

echo "*******************************************************************************"
echo "        Test case 2: Show ahead = TRUE, Show ahead legacy mode = FALSE"
echo "                     Register flag outputs = TRUE,                    "
echo "                  With no almost empty and almost full logic          "
echo "*******************************************************************************"
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_data_width=32 -gg_size=32 -gg_show_ahead=true -gg_show_ahead_legacy_mode=false -gg_register_flag_outputs=true --wave=waveform.ghw 

echo "*******************************************************************************"
echo "        Test case 3: Show ahead = TRUE, Show ahead legacy mode = FALSE"
echo "                     Register flag outputs = TRUE,                    "
echo "                  With almost empty and almost full logic             "
echo "*******************************************************************************"
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_data_width=32 -gg_size=32 -gg_show_ahead=true -gg_show_ahead_legacy_mode=false -gg_register_flag_outputs=true -gg_with_almost_empty=true -gg_with_almost_full=true --wave=waveform.ghw 

echo "*******************************************************************************"
echo "        Test case 4: Show ahead = TRUE, Show ahead legacy mode = FALSE"
echo "                     Register flag outputs = FALSE,                   "
echo "                  With no almost empty and almost full logic          "
echo "*******************************************************************************"
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_data_width=32 -gg_size=32 -gg_show_ahead=true -gg_show_ahead_legacy_mode=false -gg_register_flag_outputs=false -gg_with_count=true --wave=waveform.ghw 

echo "*******************************************************************************"
echo "        Test case 5: Show ahead = TRUE, Show ahead legacy mode = FALSE"
echo "                     Register flag outputs = FALSE,                   "
echo "                  With almost empty and almost full logic          "
echo "*******************************************************************************"
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_data_width=32 -gg_size=32 -gg_show_ahead=true -gg_show_ahead_legacy_mode=false -gg_register_flag_outputs=false -gg_with_count=true -gg_with_almost_empty=true -gg_with_almost_full=true --wave=waveform.ghw 


