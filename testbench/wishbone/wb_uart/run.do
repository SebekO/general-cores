set StdArithNoWarnings 1
set NumericStdNoWarnings 1

vsim work.main -voptargs=+acc

set StdArithNoWarnings 1
set NumericStdNoWarnings 1

do wave.do
radix -hexadecimal
run 200ms
