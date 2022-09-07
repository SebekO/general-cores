action="simulation"
sim_tool="ghdl"
target="generic"
ghdl_opt="--std=08 -frelaxed-rules"
sim_top="tb_gc_dyn_glitch_filt"

files="tb_gc_dyn_glitch_filt.vhd"
modules={"local" : ["../../../",
                    "../../../modules/common"]}
