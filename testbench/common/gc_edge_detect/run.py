#!/usr/bin/env python3

import subprocess
import shutil
import sys
import os
from pathlib import Path
from itertools import product
from vunit import VUnit
from subprocess import call
from vunit.sim_if.factory import SIMULATOR_FACTORY
import random

# Fetch the path where file exists and specify the path
# for the RTL design and Testbench
ROOT = Path(__file__).resolve().parent
RTL_PATH = ROOT / "../../../modules/common/"
TB_PATH = ROOT

# Find where the sim_utils.py is or any other python package
sys.path.append(str(ROOT))
import sim_utils

# Create VUnit instance
VU = VUnit.from_argv(compile_builtins=False)
VU.add_vhdl_builtins()
VU.add_osvvm()
VU.add_verification_components()

# Create design library
common_lib = VU.add_library("common_lib")

# Add design source files to design lib
# Define the groups of the files
src_files_list = ["gc_edge_detect.vhd"]
testbench_list = ["tb_gc_edge_detect.vhd"]

# Add the RTL source files in the common_lib
for src_file in src_files_list:
    common_lib.add_source_files(RTL_PATH/src_file)

# Add the Testbench source files in the common_lib
for tb_file in testbench_list:
    common_lib.add_source_files(TB_PATH/tb_file)

# Specify constant values to some generics
for tb in common_lib.get_test_benches():
    tb.set_generic("g_seed", random.randrange(2**31))
    tb.set_generic("g_clk_cycles", 200)

# Set the value of a generic
tb_gc_edge_detect=common_lib.test_bench("tb_gc_edge_detect");
for g_ASYNC_RST,g_PULSE_EDGE,g_CLOCK_EDGE in product([False, True], ['positive','negative'], ['positive', 'negative']):
    tb_gc_edge_detect.add_config(
        name=f"g_ASYNC_RST={g_ASYNC_RST}.g_PULSE_EDGE={g_PULSE_EDGE}.g_CLOCK_EDGE={g_CLOCK_EDGE}",
        generics=dict(g_ASYNC_RST=g_ASYNC_RST,g_PULSE_EDGE=g_PULSE_EDGE,g_CLOCK_EDGE=g_CLOCK_EDGE))

# Define arguments for compile and simulation
common_lib.set_compile_option('ghdl.a_flags', ['--std=08', '-frelaxed', '-Wc,-fprofile-arcs', '-Wc,-ftest-coverage'])
common_lib.set_sim_option("ghdl.elab_flags", ['-frelaxed-rules', '-fsynopsys', '-Wl,-lgcov'])
common_lib.set_sim_option("ghdl.sim_flags", ['--ieee-asserts=disable'])

sim_utils.vunit_enable_coverage(common_lib)

VU.main(post_run=sim_utils.vunit_postrun(Path(__file__).resolve()))
