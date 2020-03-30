# Modelsim run script for continuous integration
# execute: vsim -c -do "run_ci.do"

vsim -quiet -t 1ns -L unisim work.main

set StdArithNoWarnings 1
set NumericStdNoWarnings 1

run -all

exit

