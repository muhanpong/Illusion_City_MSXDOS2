set ::rl [open "$::T/reads.log" w]
proc on_f {} { set c [reg C]; if {$c == 0x2F || $c == 0x30} { puts $::rl [format "%.2f %02X %04X %02X" [machine_info time] $c [reg DE] [reg H]]; flush $::rl } }
debug set_bp 0xF37D {} on_f
debug set_bp 0x0117 {} { reg A 0x10 }
after time $::env(END) { exec kill -9 [pid] }
