action="simulation"
sim_tool="ghdl"
target="generic"
sim_top="tb_generic_async_fifo"
ghdl_opt="--std=08 -frelaxed-rules"

files=["tb_generic_async_fifo.vhd"]
modules={"local" : ["../../../../",
                    "../../../../modules/common",
                    "../../../../modules/genrams"]}

