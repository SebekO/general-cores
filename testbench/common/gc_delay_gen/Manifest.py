action="simulation"
sim_tool="ghdl"
sim_top="tb_gc_delay_gen"
target="generic"
ghdl_opt="--std=08 -frelaxed-rules"

files="tb_gc_delay_gen.vhd"
modules={"local" : ["../../../",
                    "../../../modules/common"]}
