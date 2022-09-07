action="simulation"
sim_tool="ghdl"
target="generic"
ghdl_opt="--std=08 -frelaxed-rules"
sim_top="tb_gc_fsm_watchdog"

files="tb_gc_fsm_watchdog.vhd"
modules={"local" : ["../../../",
                    "../../../modules/common"]}
