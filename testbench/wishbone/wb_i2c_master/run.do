vsim -quiet -t 10fs work.tst_bench_top -suppress 1270,8617,8683,8684,8822 -voptargs="+acc"

set StdArithNoWarnings 1
set NumericStdNoWarnings 1

radix -hexadecimal

run -all
