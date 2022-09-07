action = "simulation"
target = "generic"
sim_top = "tb_xwb_clock_bridge"
sim_tool = "ghdl"
ghdl_opt = "--std=08 -frelaxed-rules"
modules = { "local" :  ["../../../../"]} 

files = ["tb_xwb_clock_bridge.vhd"]

