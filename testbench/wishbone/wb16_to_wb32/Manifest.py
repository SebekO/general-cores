action = "simulation"
target = "generic"
sim_top = "tb_wb16_to_wb32"
sim_tool = "ghdl"
ghdl_opt = "--std=08 -frelaxed-rules"
modules = { "local" :  ["../../../", 
                        "../../../modules/wishbone",
                        "../../../sim/vhdl"] };
 
files = ["tb_wb16_to_wb32.vhd"]

