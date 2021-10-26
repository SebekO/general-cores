#!/bin/bash

mkdir -p doc
wbgen2 -D ./doc/wb_simple_uart.html -V simple_uart_wb.vhd -p simple_uart_pkg.vhd --cstyle struct -C wb_uart.h --hstyle record --lang vhdl -n simple_uart_wb.wb 
