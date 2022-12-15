action   = "simulation"
sim_tool = "modelsim"

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
