action   = "simulation"
target   = "generic"
sim_top  = "tst_bench_top"
sim_tool = "modelsim"
modules  = { "local" :  ["../../../", 
                        "../../../modules/wishbone"]};

files = ["tst_bench_top.v",
         "i2c_slave_model.v",
         "wb_master_model.v",
         "timescale.v"]

