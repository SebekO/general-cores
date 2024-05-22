sim_tool = "modelsim"
action = "simulation"
target = "xilinx"
fetchto = "../../../ip_cores"
vcom_opt="-mixedsvvh l -2008"
sim_top="main"
syn_device="xc7k70t"

target      = "xilinx"
syn_device  = "xc6slx45t"

top_module = "main" # for hdlmake2
sim_top    = "main" # for hdlmake3

include_dirs = [
    "../../../sim/",
    "../../../sim/wishbone",
]

modules = {
    "local" :  [
        "../../../",
        "../../../sim",
    ],
}

files = [
    "main.sv",
]
