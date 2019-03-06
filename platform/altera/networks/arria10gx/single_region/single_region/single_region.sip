set_global_assignment -entity "single_region" -library "lib_single_region" -name IP_TOOL_NAME "Qsys"
set_global_assignment -entity "single_region" -library "lib_single_region" -name IP_TOOL_VERSION "18.1"
set_global_assignment -entity "single_region" -library "lib_single_region" -name IP_TOOL_ENV "Qsys"
set_global_assignment -library "lib_single_region" -name SPD_FILE [file join $::quartus(sip_path) "single_region.spd"]
set_global_assignment -library "lib_single_region" -name MISC_FILE [file join $::quartus(sip_path) "../single_region.qsys"]

set_global_assignment -library "lib_single_region" -name MISC_FILE [file join $::quartus(sip_path) "sim/single_region.v"]
set_global_assignment -library "lib_single_region" -name MISC_FILE [file join $::quartus(sip_path) "altclkctrl_181/sim/single_region_altclkctrl_181_bjorw2i.v"]
