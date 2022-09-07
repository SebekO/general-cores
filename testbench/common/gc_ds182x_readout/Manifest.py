action   = "simulation"
sim_tool = "ghdl"
ghdl_opt = "--std=08 -frelaxed-rules"
target      = "xilinx"
syn_device  = "xc6slx45t"

sim_top = "gc_ds182x_readout_tb"

files = [
        "gc_ds182x_readout_tb.vhd",
    ]

modules = {
    "local" :  [
        "../../../",
    ],
}
