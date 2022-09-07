#!/bin/bash -e

#This is a simple script to run simulations in GHDL

TB=tb_xwb_dpram

echo "*******************************************************************************"
echo "Running simulation for $TB"

echo "*******************************************************************************"
echo "        TEST CASE 1 : Size                     = 32                            "
echo "                      Must have init file      = True                          "
echo "                      Slave 1,2 interface mode = CLASSIC / CLASSIC             "
echo "                      Slave 1,2 granularity    = WORD    / WORD                "
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed_1=$RANDOM -gg_seed_2=$RANDOM -gg_size=32 -gg_must_have_init_file=true -gg_slave1_interface_mode=CLASSIC -gg_slave2_interface_mode=CLASSIC -gg_slave1_granularity=WORD -gg_slave2_granularity=WORD --wave=waveform.ghw
echo "*******************************************************************************"

echo "*******************************************************************************"
echo "Running simulation for $TB"

echo "*******************************************************************************"
echo "        TEST CASE 2 : Size                     = 32                            "
echo "                      Must have init file      = True                          "
echo "                      Slave 1,2 interface mode = PIPELINED / PIPELINED         "
echo "                      Slave 1,2 granularity    = WORD    / WORD                "
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed_1=$RANDOM -gg_seed_2=$RANDOM -gg_size=32 -gg_must_have_init_file=true -gg_slave1_interface_mode=PIPELINED   -gg_slave2_interface_mode=PIPELINED -gg_slave1_granularity=WORD -gg_slave2_granularity=WORD --wave=waveform.ghw
echo "*******************************************************************************"

echo "*******************************************************************************"
echo "Running simulation for $TB"

echo "*******************************************************************************"
echo "        TEST CASE 3 : Size                     = 32                            "
echo "                      Must have init file      = True                          "
echo "                      Slave 1,2 interface mode = CLASSIC / PIPELINED             "
echo "                      Slave 1,2 granularity    = WORD    / WORD                "
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed_1=$RANDOM -gg_seed_2=$RANDOM -gg_size=32 -gg_must_have_init_file=true -gg_slave1_interface_mode=CLASSIC -gg_slave2_interface_mode=PIPELINED -gg_slave1_granularity=WORD -gg_slave2_granularity=WORD --wave=waveform.ghw
echo "*******************************************************************************"

echo "*******************************************************************************"
echo "Running simulation for $TB"

echo "*******************************************************************************"
echo "        TEST CASE 4 : Size                     = 32                            "
echo "                      Must have init file      = True                          "
echo "                      Slave 1,2 interface mode = PIPELINED / CLASSIC           "
echo "                      Slave 1,2 granularity    = WORD    / WORD                "
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed_1=$RANDOM -gg_seed_2=$RANDOM -gg_size=32 -gg_must_have_init_file=true -gg_slave1_interface_mode=PIPELINED -gg_slave2_interface_mode=CLASSIC -gg_slave1_granularity=WORD -gg_slave2_granularity=WORD --wave=waveform.ghw
echo "*******************************************************************************"

echo "*******************************************************************************"
echo "Running simulation for $TB"

echo "*******************************************************************************"
echo "        TEST CASE 5 : Size                     = 32                            "
echo "                      Must have init file      = True                          "
echo "                      Slave 1,2 interface mode = CLASSIC / CLASSIC             "
echo "                      Slave 1,2 granularity    = WORD    / BYTE                "
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed_1=$RANDOM -gg_seed_2=$RANDOM -gg_size=32 -gg_must_have_init_file=true -gg_slave1_interface_mode=CLASSIC -gg_slave2_interface_mode=CLASSIC -gg_slave1_granularity=WORD -gg_slave2_granularity=BYTE --wave=waveform.ghw
echo "*******************************************************************************"

echo "*******************************************************************************"
echo "Running simulation for $TB"

echo "*******************************************************************************"
echo "        TEST CASE 6 : Size                     = 32                            "
echo "                      Must have init file      = True                          "
echo "                      Slave 1,2 interface mode = PIPELINED / PIPELINED         "
echo "                      Slave 1,2 granularity    = BYTE    / WORD                "
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed_1=$RANDOM -gg_seed_2=$RANDOM -gg_size=32 -gg_must_have_init_file=true -gg_slave1_interface_mode=PIPELINED   -gg_slave2_interface_mode=PIPELINED -gg_slave1_granularity=BYTE -gg_slave2_granularity=WORD --wave=waveform.ghw
echo "*******************************************************************************"

echo "*******************************************************************************"
echo "Running simulation for $TB"

echo "*******************************************************************************"
echo "        TEST CASE 7 : Size                     = 32                            "
echo "                      Must have init file      = True                          "
echo "                      Slave 1,2 interface mode = CLASSIC / PIPELINED             "
echo "                      Slave 1,2 granularity    = BYTE    / BYTE                "
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed_1=$RANDOM -gg_seed_2=$RANDOM -gg_size=32 -gg_must_have_init_file=true -gg_slave1_interface_mode=CLASSIC -gg_slave2_interface_mode=PIPELINED -gg_slave1_granularity=BYTE -gg_slave2_granularity=BYTE --wave=waveform.ghw
echo "*******************************************************************************"

