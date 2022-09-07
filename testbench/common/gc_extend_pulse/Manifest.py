action="simulation"
sim_tool="ghdl"
target="generic"
ghdl_opt="--std=08 -frelaxed-rules"
sim_top="tb_gc_extend_pulse"

files="tb_gc_extend_pulse.vhd"
modules={"local" : ["../../../",
                    "../../../modules/common"]}

