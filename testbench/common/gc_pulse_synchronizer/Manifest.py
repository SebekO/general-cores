action="simulation"
sim_tool="ghdl"
target="generic"
ghdl_opt="--std=08 -frelaxed-rules"
sim_top="tb_gc_pulse_synchronizer"

files="tb_gc_pulse_synchronizer.vhd"
modules={"local" : ["../../../",
                    "../../../modules/common"]}

