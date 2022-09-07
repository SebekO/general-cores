action="simulation"
sim_tool="ghdl"
target="xilinx"
syn_device="xc6slx45t"
sim_top="tb_generic_spram"
ghdl_opt="--std=08 -frelaxed-rules"

files=["tb_generic_spram.vhd"]
modules={"local" : ["../../../../",
                    "../../../../modules/common",
                    "../../../../modules/genrams"]}

