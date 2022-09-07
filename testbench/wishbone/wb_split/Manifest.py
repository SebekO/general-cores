action = "simulation"
target = "generic"
sim_top = "tb_xwb_split"
sim_tool = "ghdl"
ghdl_opt = "--std=08 -frelaxed-rules"
modules = { "local" :  ["../../../", 
                        "../../../modules/wishbone"]}

files = ["tb_xwb_split.vhd"]

