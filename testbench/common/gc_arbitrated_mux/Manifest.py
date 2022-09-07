action="simulation"
sim_tool="ghdl"
sim_top="tb_gc_arbitrated_mux"
target="generic"
ghdl_opt="--std=08 -frelaxed-rules"

files="tb_gc_arbitrated_mux.vhd"
modules={"local" : ["../../../",
                    "../../../modules/common",
                    "../../../modules/genrams"]}
