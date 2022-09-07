action="simulation"
sim_tool="ghdl"
target="altera"
syn_device  = "5agxmb1g4f"
sim_top="tb_gc_shiftreg"
ghdl_opt="--std=08 -frelaxed-rules"

files=["tb_gc_shiftreg.vhd"]
modules={"local" : ["../../../../"]}# ,
                  #  "../../../../modules/common",
                  #  "../../../../modules/genrams"]}

