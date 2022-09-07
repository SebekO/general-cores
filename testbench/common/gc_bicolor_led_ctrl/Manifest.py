action   = "simulation"
sim_tool = "ghdl"
ghdl_opt = "--std=08 -frelaxed-rules"

target      = "xilinx"
syn_device  = "xc6slx45t"

top_module = "gc_bicolor_led_ctrl_tb" # for hdlmake2
sim_top    = "gc_bicolor_led_ctrl_tb" # for hdlmake3

files = [
        "gc_bicolor_led_ctrl_tb.vhd",
    ]

modules = {
    "local" :  [
        "../../../",
        "../../../modules/common"
    ],
}
