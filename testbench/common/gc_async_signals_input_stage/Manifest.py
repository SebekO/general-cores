action="simulation"
target="generic"
sim_tool="ghdl"
ghdl_opt="--std=08 -frelaxed-rules"
sim_top="tb_gc_async_signals_input_stage"

files="tb_gc_async_signals_input_stage.vhd"
modules={"local" : ["../../../",
                    "../../../modules/common"]}
