action = "simulation"
target = "generic"
sim_top = "tb_xwb_axi4lite_bridge"
sim_tool = "ghdl"
ghdl_opt = "--std=08 -frelaxed-rules"
modules = { "local" :  ["../../../", 
                        "../../../modules/wishbone",
                        "../../../modules/axi"] };

files = ["tb_xwb_axi4lite_bridge.vhd"]

