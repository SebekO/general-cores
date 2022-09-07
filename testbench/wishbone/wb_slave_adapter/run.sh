#!/bin/bash -e

#This is a script to run multiple simulations in Modelsim

TB=tb_wb_slave_adapter

echo "Running Simulation for $TB"
echo ""

echo "****************    TEST CASE 1    ***********************"
echo "Master: use_struct=TRUE, mode=CLASSIC, granularity=BYTE"
echo "Slave:  use_struct=TRUE, mode=CLASSIC, granularity=BYTE"
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_master_use_struct=TRUE -gg_master_mode=classic -gg_master_granularity=byte -gg_slave_use_struct=TRUE -gg_slave_mode=classic -gg_slave_granularity=BYTE

echo ""
echo "****************    TEST CASE 2    ***********************"
echo "Master: use_struct=TRUE, mode=CLASSIC, granularity=BYTE"
echo "Slave:  use_struct=FALSE, mode=CLASSIC, granularity=BYTE"
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_master_use_struct=TRUE -gg_slave_use_struct=FALSE -gg_master_mode=CLASSIC -gg_master_granularity=BYTE -gg_slave_mode=CLASSIC -gg_slave_granularity=BYTE

echo ""
echo "****************    TEST CASE 3    ***********************"
echo "Master: use_struct=FALSE, mode=CLASSIC, granularity=BYTE"
echo "Slave:  use_struct=TRUE, mode=CLASSIC, granularity=BYTE"
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_master_use_struct=FALSE -gg_slave_use_struct=TRUE -gg_master_mode=CLASSIC -gg_master_granularity=BYTE -gg_slave_mode=CLASSIC -gg_slave_granularity=BYTE

echo ""
echo "****************    TEST CASE 4    ***********************"
echo "Master: use_struct=FALSE, mode=CLASSIC, granularity=BYTE"
echo "Slave:  use_struct=FALSE, mode=CLASSIC, granularity=BYTE"
ghdl -r --std=08 -frelaxed $TB -gg_seed=$RANDOM -gg_master_use_struct=FALSE -gg_slave_use_struct=FALSE -gg_master_mode=CLASSIC -gg_master_granularity=BYTE -gg_slave_mode=CLASSIC -gg_slave_granularity=BYTE 

echo ""
echo "****************    TEST CASE 5    ***********************"
echo "Master: use_struct=TRUE, mode=CLASSIC, granularity=BYTE"
echo "Slave:  use_struct=TRUE, mode=PIPELINED, granularity=BYTE"
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_master_use_struct=TRUE -gg_slave_use_struct=FALSE -gg_master_mode=CLASSIC -gg_master_granularity=BYTE -gg_slave_mode=PIPELINED -gg_slave_granularity=BYTE

echo ""
echo "****************    TEST CASE 6    ***********************"
echo "Master: use_struct=TRUE, mode=PIPELINED, granularity=BYTE"
echo "Slave:  use_struct=TRUE, mode=CLASSIC, granularity=BYTE"
ghdl -r --std=08 -frelaxed $TB -gg_seed=$RANDOM -gg_master_use_struct=TRUE -gg_slave_use_struct=TRUE -gg_master_mode=PIPELINED -gg_master_granularity=BYTE -gg_slave_mode=CLASSIC -gg_slave_granularity=BYTE

echo ""
echo "****************    TEST CASE 7    ***********************"
echo "Master: use_struct=TRUE, mode=CLASSIC, granularity=BYTE"
echo "Slave:  use_struct=TRUE, mode=CLASSIC, granularity=WORD"
ghdl -r --std=08 -frelaxed $TB -gg_seed=$RANDOM -gg_master_use_struct=TRUE -gg_slave_use_struct=FALSE -gg_master_mode=CLASSIC -gg_master_granularity=BYTE -gg_slave_mode=CLASSIC -gg_slave_granularity=WORD

echo ""
echo "****************    TEST CASE 8    ***********************"
echo "Master: use_struct=TRUE, mode=PIPELINED, granularity=WORD"
echo "Slave:  use_struct=TRUE, mode=CLASSIC, granularity=WORD"
ghdl -r --std=08 -frelaxed $TB -gg_seed=$RANDOM -gg_master_use_struct=TRUE -gg_slave_use_struct=FALSE -gg_master_mode=PIPELINED -gg_master_granularity=WORD -gg_slave_mode=CLASSIC -gg_slave_granularity=WORD
