# SPDX-FileCopyrightText: 2023 CERN (home.cern)
#
# SPDX-License-Identifier: CERN-OHL-W-2.0+

action   = "simulation"
sim_tool = "ghdl"

target      = "xilinx"
syn_device  = "xc6slx45t"

top_module = "tb_fifo"

files = [
    top_module + ".vhd",
    "tb_32_64.vhd", "tb_64_32.vhd", "tb_8_32.vhd", "tb_32_8_ahead.vhd",
    ]

modules = {
    "local" :  [
        "../../../",
    ],
}
