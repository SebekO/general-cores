action = "simulation"
sim_tool = "modelsim"
target = "xilinx"
top_module = "main"
fetchto="../../../ip_cores"
include_dirs=["../../../sim"]

modules = { "local" :  "../../../" };

files = ["main.sv", "SIM_CONFIG_S6_SERIAL.v", "glbl.v" ]

vlog_opt= "+incdir+../../../sim"
