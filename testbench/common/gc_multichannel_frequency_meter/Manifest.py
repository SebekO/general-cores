action="simulation"
sim_tool="ghdl"
target="generic"
ghdl_opt="--std=08 -frelaxed-rules"
sim_top="tb_gc_multichannel_frequency_meter"

files="tb_gc_multichannel_frequency_meter.vhd"
modules={"local" : ["../../../",
                    "../../../modules/common"]}

