action="simulation"
sim_tool="ghdl"
target="generic"
ghdl_opt="--std=08 -frelaxed-rules"
sim_top="tb_gc_async_counter_diff"

files="tb_gc_async_counter_diff.vhd"
modules={"local" : ["../../../",
                    "../../../modules/common"]}
