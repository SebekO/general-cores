set_global_assignment -entity "global_region" -library "lib_global_region" -name IP_TOOL_NAME "Qsys"
set_global_assignment -entity "global_region" -library "lib_global_region" -name IP_TOOL_VERSION "18.1"
set_global_assignment -entity "global_region" -library "lib_global_region" -name IP_TOOL_ENV "Qsys"
set_global_assignment -library "lib_global_region" -name SPD_FILE [file join $::quartus(sip_path) "global_region.spd"]
set_global_assignment -library "lib_global_region" -name MISC_FILE [file join $::quartus(sip_path) "../global_region.qsys"]

set_global_assignment -library "lib_global_region" -name MISC_FILE [file join $::quartus(sip_path) "sim/global_region.vhd"]
set_global_assignment -library "lib_global_region" -name MISC_FILE [file join $::quartus(sip_path) "altclkctrl_181/sim/global_region_altclkctrl_181_cf6o3fq.vhd"]
