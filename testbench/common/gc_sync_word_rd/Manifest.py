action="simulation"
sim_tool="ghdl"
target="xilinx"
syn_device="xc6slx45t"
sim_top="tb_gc_sync_word_rd"
ghdl_opt="--std=08 -frelaxed-rules"

files=["tb_gc_sync_word_rd.vhd"]
modules={"local" : ["../../../",
                    "../../../modules/common"]}
