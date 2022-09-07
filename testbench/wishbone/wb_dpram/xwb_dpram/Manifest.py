action = "simulation"
target = "xilinx"
syn_device="xc6slx45t"
sim_top = "tb_xwb_dpram"
sim_tool = "ghdl"
ghdl_opt = "--std=08 -frelaxed-rules"
modules = { "local" :  ["../../../../"]} 

files = ["tb_xwb_dpram.vhd"]

