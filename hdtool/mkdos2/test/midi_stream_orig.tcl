# MIDI stream comparison, original game (floppy, MIDI mode): log the first 6000 non-zero data bytes written to MSX-MIDI ports E8/E9.
# env: T (output dir), D (disk dir with D1.dsk..D8.dsk, DU.dsk), FORCE14 (path of phase0/e8f5/force_e8f5.tcl)
set ::T $::env(T)
set ::D $::env(D)
set ::FORCE ""
source $::env(FORCE14)
set ::mf [open "$::env(T)/midi.txt" w]
set ::nm 0
proc on_midi {} { if {$::wp_last_value != 0 && $::nm < 6000} { puts $::mf [format "%02X %02X" [expr {$::wp_last_address & 0xFF}] $::wp_last_value]; incr ::nm } }
after time 13 { debug set_watchpoint write_io {0xE8 0xE9} {} on_midi }
after time 28 { key 8 0x40 }
after time 30 { key 8 0x01 }
after time 36 { key 8 0x40 }
after time 37 { key 8 0x40 }
after time 39 { key 8 0x01 }
for {set t 80} {$t <= 140} {incr t 6} { after time $t {key 8 0x01} }
after time 141 { close $::mf; exit }
