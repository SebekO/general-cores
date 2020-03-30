# Modelsim run script with full logging for debugging
# execute: vsim -do "run.do"

vsim -quiet -t 1ns -L unisim -classdebug -voptargs=+acc work.main

set StdArithNoWarnings 1
set NumericStdNoWarnings 1

log -r /*

run -all
