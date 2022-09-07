action       = "simulation"
target       = "xilinx"
fetchto      = "../../../ip_cores"
sim_tool     = "modelsim"
top_module   = "main"
vcom_opt     = "-mixedsvvh l -2008"
syn_device   = "xc7k70t"
include_dirs = ["../../../sim", "../include"]

modules = { "local" :  "../../../" };

files = ["main.sv"]

vlog_opt= "+incdir+../../../sim"
