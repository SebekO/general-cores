action="simulation"
sim_tool="ghdl"
target="xilinx"
syn_device="xc6slx45t"
sim_top="tb_inferred_async_fifo_dual_rst"
ghdl_opt="--std=08 -frelaxed-rules"

files=["tb_inferred_async_fifo_dual_rst.vhd"]
modules={"local" : ["../../../../",
                    "../../../../modules/common",
                    "../../../../modules/genrams"]}
