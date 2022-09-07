action="simulation"
sim_tool="ghdl"
target="xilinx"
syn_device="xc6slx45t"
sim_top="tb_generic_dpram_sameclock"
ghdl_opt="--std=08 -frelaxed-rules"

files=["tb_generic_dpram_sameclock.vhd"]

modules={"local" : ["../../../../",
                    "../../../../modules/common",
                    "../../../../modules/genrams"]}
