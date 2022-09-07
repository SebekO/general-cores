action = "simulation"
target = "generic"
sim_top = "tb_wb_indirect"
sim_tool = "ghdl"
ghdl_opt = "--std=08 -frelaxed-rules"

modules = { "local" :  ["../../../", "../../../sim/vhdl"] };

files = ["tb_wb_indirect.vhd"]

