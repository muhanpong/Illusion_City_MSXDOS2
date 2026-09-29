# MIDI stream comparison, DOS2 build: same log as midi_stream_orig.tcl. env: T, HD (MIDI image).  Compare T/midi.txt of both: they must be identical.
set throttle off
set firmwareswitch off
hda $::env(HD)
reset
proc key {row mask} { keymatrixdown $row $mask ; after time 0.2 "keymatrixup $row $mask" }
set ::mf [open "$::env(T)/midi.txt" w]
set ::nm 0
proc on_midi {} { if {$::wp_last_value != 0 && $::nm < 6000} { puts $::mf [format "%02X %02X" [expr {$::wp_last_address & 0xFF}] $::wp_last_value]; incr ::nm } }
after time 27.5 { debug set_watchpoint write_io {0xE8 0xE9} {} on_midi }
after time 28 { type "ICITY\r" }
after time 36 { key 8 0x40 }
after time 38 { key 8 0x01 }
after time 41 { key 8 0x40 }
after time 42 { key 8 0x40 }
after time 43 { key 8 0x01 }
for {set t 70} {$t <= 130} {incr t 6} { after time $t {key 8 0x01} }
after time 131 { close $::mf; exit }
