sim_tool= "ghdl" 
sim_top="tb_wb_slave_adapter"
action = "simulation"
target = "generic"
ghdl_opt="--std=08 -frelaxed-rules"
files=["tb_wb_slave_adapter.vhd"]
modules={"local" : ["../../../",
                    "../../../modules/wishbone"]}
