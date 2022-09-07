action="simulation"
sim_tool="ghdl"
target="xilinx"
syn_device="xc6slx45t" #"5agxmb1g4f"
ghdl_opt="--std=08 -frelaxed-rules"
sim_top="tb_gc_delay_line"

files="tb_gc_delay_line.vhd"
modules={"local" : ["../../../",
                    "../../../modules/common",
                    "../../../modules/genrams"]}
