#!/bin/bash -e

#This is a simple script to run simulations
#in GHDL

TB=tb_gc_dual_pi_controller

echo "Running simulation for $TB"

echo "      TEST CASE 1 : Frequency mode             "
echo "                    Error Bits          = 12   "
echo "                    Dacval_bits         = 16   " 
echo "                    Output_bias         = 32767"
echo "                    Integrator_fracbits = 16   " 
echo "                    Integrator_overbits = 6    "
echo "                    Coef_bits           = 16   "
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_mode=1 -gg_error_bits=12 -gg_dacval_bits=16 -gg_output_bias=32767 -gg_integrator_fracbits=16 -gg_integrator_overbits=6 -gg_coef_bits=16 
echo "*******************************************************************************"


echo "      TEST CASE 2 : Phase mode                 "
echo "                    Error Bits          = 12   "
echo "                    Dacval_bits         = 16   " 
echo "                    Output_bias         = 32767"
echo "                    Integrator_fracbits = 16   " 
echo "                    Integrator_overbits = 6    "
echo "                    Coef_bits           = 16   "
ghdl -r --std=08 -frelaxed-rules $TB -gg_seed=$RANDOM -gg_mode=0 -gg_error_bits=12 -gg_dacval_bits=16 -gg_output_bias=32767 -gg_integrator_fracbits=16 -gg_integrator_overbits=6 -gg_coef_bits=16 
echo "*******************************************************************************"
