action = "simulation"
target = "generic"
sim_top = "tb_wb_i2c_bridge"
sim_tool = "ghdl"
ghdl_opt = "--std=08 -frelaxed-rules"
modules = { "local" :  ["../../../", "../../../sim/wb_i2c_bridge"] };

files = ["tb_wb_i2c_bridge.vhd"]

