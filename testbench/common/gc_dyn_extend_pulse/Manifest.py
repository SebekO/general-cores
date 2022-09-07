action="simulation"
target="generic"
sim_tool="ghdl"
ghdl_opt="--std=08 -frelaxed-rules"
sim_top="tb_gc_dyn_extend_pulse"

files="tb_gc_dyn_extend_pulse.vhd"
modules={"local" : ["../../../",
                    "../../../modules/common"]}
