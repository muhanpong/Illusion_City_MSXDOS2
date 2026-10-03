set ::mf [open "$::T/midi.txt" w]
set ::nm 0
proc on_midi {} { if {$::wp_last_value != 0 && $::nm < 6000 && [machine_info time] > 26} { puts $::mf [format "%02X %02X" [expr {$::wp_last_address & 0xFF}] $::wp_last_value]; incr ::nm; if {$::nm % 50 == 0} { flush $::mf } } }
debug set_watchpoint write_io {0xE8 0xE9} {} on_midi
after time $::env(END) { close $::mf; exec kill -9 [pid] }
