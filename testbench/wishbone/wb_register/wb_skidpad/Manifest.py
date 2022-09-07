action = "simulation"
target = "generic"
sim_top = "tb_wb_skidpad"
sim_tool = "ghdl"
ghdl_opt = "--std=08 -frelaxed-rules"
modules = { "local" :  ["../../../../"]} 

files = ["tb_wb_skidpad.vhd"]

