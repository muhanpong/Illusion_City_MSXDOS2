# log writes to candidate free areas (kernel tail E947-E9FF, page0 0090-00FF) and all BDOS function codes
set ::wl [open "$::T/writes.log" w]
array set ::fn {}
proc on_w {} {
  set a $::wp_last_address; set pc [reg PC]
  if {[machine_info time] < 13} return
  set k [format "%04X@%04X" $a $pc]
  if {![info exists ::seenw($k)]} { set ::seenw($k) 1; puts $::wl [format "%.2f W %04X=%02X PC=%04X FC=%02X" [machine_info time] $a $::wp_last_value $pc [debug read ioports 0xFC]]; flush $::wl }
}
debug set_watchpoint write_mem {0xE947 0xE9FF} {} on_w
debug set_watchpoint write_mem {0x0090 0x00FF} {} on_w
proc on_f {} { set c [reg C]; if {![info exists ::fn($c)]} { set ::fn($c) 1; puts $::wl [format "%.2f BDOS C=%02X DE=%04X HL=%04X ret=%04X" [machine_info time] $c [reg DE] [reg HL] [peek16 [reg SP]]]; flush $::wl } }
debug set_bp 0xF37D {} on_f
