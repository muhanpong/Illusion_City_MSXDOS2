# MIDI build test: pick MIDI, start menu -> save point, load user-disk slot 3, log music reads (L=80h = disk-1 forced)
# and mapper violations (logical->physical outside the launcher allocation).  Reading of song data must show up as
# MUSIC read lines with 5EC0h != disk 1 while the game is on another disk.
# env: HD (MIDI image), T (output dir), ERRCTX/EDOS (launcher error label addresses from icity_m.lst)
set throttle off
set firmwareswitch off
hda $::env(HD)
reset
set ::lg [open "$::env(T)/log.txt" w]
proc L {m} { puts $::lg "[format %.2f [machine_info time]] $m"; flush $::lg }
proc key {row mask} { keymatrixdown $row $mask ; after time 0.2 "keymatrixup $row $mask" }
set ::viol 0
proc on_map {} {
  set pc [reg PC]; set v [expr {$::wp_last_value & 0x1F}]
  if {$pc >= 0xE000 && $pc < 0xEA00 && ($v < 4 || $v > 0x18)} { incr ::viol; if {$::viol < 10} { L [format "VIOLATION port %02X=%02X PC=%04X" [expr {$::wp_last_address & 0xFF}] $::wp_last_value $pc] } }
}
proc on_hook {} {
  if {[reg C]==0x2F} { if {[reg L]==0x80} { L [format "MUSIC read DE=%04X curdisk?5EC0=%02X" [reg DE] [peek 0x5EC0]] } elseif {[reg DE]==0} { L [format "DISKCHECK 5EC0=%02X" [peek 0x5EC0]] } }
}
after time 27.5 { debug set_bp 0x0090 {([debug read ioports 0xFC] & 0x1F) != 3} on_hook; debug set_watchpoint write_io {0xFC 0xFF} {} on_map; debug set_bp $::env(ERRCTX) {} { L ERR_CTX }; debug set_bp $::env(EDOS) {} { L E_DOS } }
after time 28 { type "ICITY\r" }
after time 36 { key 8 0x40 }
after time 38 { key 8 0x01 }
after time 41 { key 8 0x01 }
after time 55 { key 8 0x40 }
after time 56 { key 8 0x40 }
after time 57 { key 8 0x40 }
after time 59 { key 8 0x01 }
after time 68 { key 8 0x40 }
after time 69 { key 8 0x40 }
after time 70 { key 8 0x40 }
after time 76 { key 8 0x01 }
foreach t {70 80 90 100 120 150 180} { after time $t "screenshot -raw $::env(T)/s$t.png" }
after time 181 { L "violations=$::viol"; close $::lg; exit }
