action="simulation"
target="generic"
sim_tool="ghdl"
ghdl_opt="--std=08 -frelaxed-rules"
sim_top="tb_gc_glitch_filt"

files="tb_gc_glitch_filt.vhd"
modules={"local" : ["../../../",
                    "../../../modules/common"]}
