action = "simulation"
target = "generic"
sim_top = "tb_sdb_rom"
sim_tool = "ghdl"
ghdl_opt = "--std=08 -frelaxed-rules"
modules = { "local" :  ["../../../../"]} 

files = ["tb_sdb_rom.vhd"]

