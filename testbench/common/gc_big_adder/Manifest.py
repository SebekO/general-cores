action="simulation"
sim_tool="ghdl"
target="xilinx"
syn_device="xc6slx45t"
top_module="tb_gc_big_adder" #hdlmake2
sim_top="tb_gc_big_adder"   #hdlmake3

ghdl_opt="--std=08 -frelaxed-rules"
files = ["tb_gc_big_adder.vhd"]

modules= {"local" : ["../../../",
		     "../../../modules/common"]}
