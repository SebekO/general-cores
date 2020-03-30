sim_tool   = "modelsim"
sim_top    = "main"
action     = "simulation"
vcom_opt   = "-93 -mixedsvvh"

include_dirs = [
    "../../../../sim",
]

files = [
    "main.sv",    
]

modules = {
    "local" : [
        "../../../../",
    ],
}
