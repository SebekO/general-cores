action="simulation"
sim_tool="ghdl"
target="xilinx"
syn_device="generic"
sim_top="tb_gc_reset"
ghdl_opt="--std=08 -frelaxed-rules"

files=["tb_gc_reset.vhd"]
modules={"local" : ["../../../",
                    "../../../modules/common"]}

