action = "simulation"
target = "generic"
sim_top = "tb_xwb_metadata"
sim_tool = "ghdl"
ghdl_opt = "--std=08 -frelaxed-rules"
modules = { "local" :  ["../../../", 
                        "../../../modules/wishbone",
                        "../../../sim/vhdl"] };

files = ["tb_xwb_metadata.vhd"]

