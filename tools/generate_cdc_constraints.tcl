##-------------------------------------------------------------------------------
## CERN BE-CEM-EDL
## General Cores
## https://www.ohwr.org/projects/general-cores
##-------------------------------------------------------------------------------
##
## Tcl script to produce CDC (Clock Domain Crossing) constraints for the CDC primitives
## used in your Vivado design:
## - gc_sync
## - gc_sync_register
## - gc_reset_multi_aasd
##
## Instructions for use:
## - synthesize your design
## - open the synthesized design in Vivado
## - run this script (source generate_cdc_constraints.tcl)
## - the result of operation is a file called "gencores_constraints.xdc". Add it
##   to the project's sources.
## - note: you must rerun this script every time you change (add/remove/modify)
##   gencores's CDC primtives in your design.
## - enjoy and profit!
##
##-------------------------------------------------------------------------------
## Copyright CERN 2023
##-------------------------------------------------------------------------------
## This Source Code Form is subject to the terms of the Mozilla Public License,
## version 2.0. If a copy of the MPL was not distributed with this file, You can
## obtain one at https://mozilla.org/MPL/2.0/.
##-------------------------------------------------------------------------------

proc generate_gc_sync_constraints { f_out } {
    set the_cells [ get_cells -hier -filter { REF_NAME=~gc_sync* } ]
    set count 0

    foreach cell $the_cells {

        set cell_name [get_property REF_NAME [get_cells $cell]]

        if {[string first "gc_sync_register" $cell_name ] != -1} {
            continue
        }

#skip gc_sync_ffs instances (as they contain a gc_sync inside)
        if {[string first "gc_sync_ffs" $cell_name] != -1} {
            puts $f_out "#WARNING: skip gc_sync_ffs cell '$cell'"
            continue
        }

        set dst_ff_clr [get_pins "$cell/sync_*.sync*_*/CLR" ]
        set dst_ff [get_cells "$cell/sync_*.sync0_reg*" ]

        if { "$dst_ff" == "" } {
            set dst_ff [get_cells -hier -filter "name=~$cell/sync_*.sync0_reg*" ]
        }
        if { "$dst_ff_clr" == "" } {
            set dst_ff_clr [get_pins -hier -filter "name=~$cell/sync_*.sync*_*/CLR" ]
        }

        if { "$dst_ff" == "" } {
            puts $f_out "#WARNING: can't find destination FF for cell '$cell'"
            continue
        }

        set clk [ get_clocks -of_objects [ get_pins -filter {REF_PIN_NAME=~clk_i*} -of [get_cells $cell]  ] ]

        if { [ llength $clk] == 0 } {
            puts $f_out "#WARNING: cell '$cell' has no clock, skipping"
            continue
        }

        puts $f_out "#DST_FF $dst_ff"
        
        set dst_fan_in [ all_fanin -startpoints_only -flat [ get_pins "$dst_ff/D"] ]

        puts $f_out "# fan-in: " 
        foreach s $dst_fan_in {
            puts $f_out "# $s"
            #report_property $src_cell
        }


        set src_clk_pins [ get_pins -filter {IS_CLOCK==1} $dst_fan_in ]
        set src_cell_pins [ get_pins -filter {DIRECTION==OUT} $dst_fan_in ]
        set src_ports [ get_ports $dst_fan_in ]
        

        #set src_cells [get_cells -of_objects [get_pins -filter {IS_LEAF && DIRECTION == OUT} -of_objects [get_nets -segments -of_objects [get_pins "$dst_ff/D"]]]]
        #set src_ff [ get_pins -filter {DIRECTION == OUT} -of_objects $src_cells ]
        set clk_period [get_property PERIOD [ lindex $clk 0 ] ]

        #report_property [ get_cells $src_cells ]

        foreach s $src_clk_pins {
            puts $f_out "#SRC-CLK: $s"
            #report_property $src_cell
        }
        foreach s $src_ports {
            puts $f_out "#SRC-PORT: $s"
            #report_property $src_cell
        }
        foreach s $src_cell_pins {
            puts $f_out "#SRC-PIN: $s"
            #report_property $src_cell
        }

        set srcs [ concat $src_clk_pins $src_ports $src_cell_pins ]



        if { [ llength $srcs] == 0 } {
            puts $f_out "# Warning, no fan-in found for $cell"
            continue
        }

        puts $f_out "#Cell: $cell, src $src_clk_pins $src_ports, dst $dst_ff, clock $clk, period $clk_period"
        puts $f_out "set_max_delay $clk_period -datapath_only -from { $src_clk_pins $src_ports $src_cell_pins } -to { $dst_ff }"
        foreach clr_pin $dst_ff_clr {
            puts $f_out "set_false_path -to { $clr_pin }"
        }
        incr count
    }

    return $count
}

proc generate_gc_sync_register_constraints { f_out } {
    set the_cells [ get_cells -hier -filter { REF_NAME=~gc_sync_register* } ]
    set count 0

    foreach cell $the_cells {

        set dst_ff_clr [get_pins "$cell/sync*_*[*]/CLR" ]
        set dst_ff [get_cells "$cell/sync0_*[*]" ]


        if { "$dst_ff" == "" } {
            set dst_ff [get_cells -hier -filter "name=~$cell/sync0_*[*]" ]
        }
        if { "$dst_ff_clr" == "" } {
            set dst_ff_clr [get_pins -hier -filter "name=~$cell/sync*_*[*]/CLR" ]
        }

        #puts $dst_ff

        if { "$dst_ff" == "" } { 
            puts $f_out "#WARNING: can't find destination FF for cell '$cell'"
            continue
        }

        set clk [ get_clocks -of_objects [ get_pins -filter {REF_PIN_NAME=~clk_i*} -of $cell ] ]
        
        if { [ llength $clk] == 0 } {
            puts $f_out "#WARNING: cell '$cell' has no clock, skipping"
            continue
        }


        set all_src_ffs []
        foreach dst_cell $dst_ff {
            puts "DST_CELL: $dst_cell"
            #set src_ff [get_cells -of_objects [get_pins -filter {IS_LEAF && DIRECTION == OUT} -of_objects [get_nets -segments -of_objects [get_pins "$dst_cell/D"]]]]
            set src_cell [get_cells -of_objects [get_pins -filter {IS_LEAF && DIRECTION == OUT} -of_objects [get_nets -segments -of_objects [get_pins "$dst_cell/D"]]]]
            puts "SRC_CELL $src_cell"
            lappend all_src_ffs [ lindex $src_cell 0 ]
        }


        
        set clk_period [get_property PERIOD [ lindex $clk 0 ] ]
        #foreach src_cell $src_cells {
            #puts "SRC: $src_cell"
        #}
        puts "Cell: $cell, src $all_src_ffs, dst $dst_ff, clock $clk, period $clk_period"
        puts $f_out "set_max_delay $clk_period -quiet -datapath_only -from { $all_src_ffs } -to { $dst_ff }"
        puts $f_out "set_bus_skew $clk_period -quiet -from { $all_src_ffs } -to { $dst_ff }"
        
        foreach clr_pin $dst_ff_clr {
            puts $f_out "set_false_path -to { $clr_pin }"
        }
        incr count
    }

    return $count
}

proc generate_gc_reset_multi_aasd_constraints { f_out } {
    set the_cells [ get_cells -hier -filter { REF_NAME=~gc_reset_multi_aasd* } ]
    set count 0

    foreach cell $the_cells {

        set dst_ff_clr [get_pins "$cell/*rst_chains_reg[*]/CLR" ]
        if { "$dst_ff_clr" == "" } {
            set dst_ff_clr [get_pins -hier -filter "name=~$cell/*rst_chains_reg[*]/CLR" ]
        }

        if { "$dst_ff_clr" == "" } { 
            puts $f_out "#WARNING: can't find destination FF CLR pin for cell '$cell'"
            continue
        }

        foreach clr_pin $dst_ff_clr {
            puts $f_out "set_false_path -to { $clr_pin }"
        }
        incr count
    }

    return $count
}

proc generate_gc_falsepath_waiver_constraints { f_out } {
    set the_cells [ get_cells -hier -filter { REF_NAME=~gc_falsepath_waiver* } ]
    set count 0

    foreach cell $the_cells {

        set src_ff [get_pins "$cell/in_i[*]" ]
        if { "$src_ff" == "" } {
            set src_ff [get_pins -hier -filter "name=~$cell/in_i[*]" ]
        }

        if { "$src_ff" == "" } { 
            puts $f_out "#WARNING: can't find source pin for '$cell'"
            continue
        }

        foreach pin $src_ff {
            puts $f_out "set_false_path -from { $pin }"
        }
        incr count
    }

    return $count
}


set f_out [open "gencores_constraints.xdc" w]
set n_gc_sync_cells [ generate_gc_sync_constraints $f_out ]
set n_gc_sync_register_cells [ generate_gc_sync_register_constraints $f_out ]
set n_gc_reset_multi_aasd_cells  [ generate_gc_reset_multi_aasd_constraints $f_out ]
##set n_gc_falsepath_waiver_cells  [ generate_gc_falsepath_waiver_constraints $f_out ]
puts "gencores CDC statistics: "
puts " - gc_sync:             $n_gc_sync_cells instances"
puts " - gc_sync_register:    $n_gc_sync_register_cells instances"
puts " - gc_reset_multi_aasd: $n_gc_reset_multi_aasd_cells instances"
#puts " - gc_falsepath_waiver: $n_gc_falsepath_waiver_cells instances"

close $f_out

