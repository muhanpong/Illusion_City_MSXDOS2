set ::wl [open "$::T/s1.log" w]
proc W {m} { puts $::wl "[format %.2f [machine_info time]] $m"; flush $::wl }
proc on_f {} { W [format "BDOS C=%02X DE=%04X HL=%04X ret=%04X cur=%d w=%04X" [reg C] [reg DE] [reg HL] [peek16 [reg SP]] $::curdisk [peek16 0x5EC0]] }
debug set_bp 0xF37D {} on_f
proc on_w {} { set a $::wp_last_address; set k [format "%04X@%04X" $a [reg PC]]
  if {[machine_info time] < 26} return
  if {![info exists ::sw($k)]} { set ::sw($k) 1; W [format "W %04X=%02X PC=%04X" $a $::wp_last_value [reg PC]] } }
foreach r {{0xE941 0xE96E} {0xE96F 0xE9FF} {0xDD00 0xDD91} {0xDF7E 0xDFFE} {0x0038 0x0038} {0x0055 0x0079} {0x007A 0x007F} {0x0090 0x00FF} {0x0003 0x0054} {0xFB30 0xFCAF}} {
  debug set_watchpoint write_mem $r {} on_w }
set ::nk 0
debug set_watchpoint write_io {0xD8 0xDB} {[machine_info time] > 26} { incr ::nk; if {$::nk < 40} { W [format "KANJI port %02X=%02X PC=%04X" $::wp_last_address $::wp_last_value [reg PC]] } }
