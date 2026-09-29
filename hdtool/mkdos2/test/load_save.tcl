# openMSX test: boot Nextor HD, run ICITY, load user-disk save slot $SLOT (1-8), play a while.
# env: HD, T, SLOT, optional ERRCTX/EDOS
set throttle off
set firmwareswitch off
hda $::env(HD)
reset
set ::T $::env(T)
set ::lg [open "$::T/log.txt" w]
proc L {m} { puts $::lg "[format %.2f [machine_info time]] $m"; flush $::lg }
proc key {row mask} { keymatrixdown $row $mask ; after time 0.2 "keymatrixup $row $mask" }
set ::nh 0
proc on_hook {} { incr ::nh; if {[reg C]==0x2F && [reg DE]==0} { L [format "DISKCHECK ret=%04X 5EC0=%02X" [peek16 [reg SP]] [peek 0x5EC0]] } ; if {[reg C]==0x30} { L [format "WRITE DE=%04X H=%02X" [reg DE] [reg H]] } }
set ::viol 0
proc on_map {} {
  set pc [reg PC]; set v [expr {$::wp_last_value & 0x1F}]
  if {$pc >= 0xE000 && $pc < 0xEA00 && ($v < 4 || $v > 0x18)} { incr ::viol; if {$::viol < 10} { L [format "VIOLATION port %02X=%02X PC=%04X" [expr {$::wp_last_address & 0xFF}] $::wp_last_value $pc] } }
}
after time 27.5 {
  debug set_bp 0x0090 {([debug read ioports 0xFC] & 0x1F) != 3} on_hook
  debug set_watchpoint write_io {0xFC 0xFF} {} on_map
  if {[info exists ::env(ERRCTX)]} { debug set_bp $::env(ERRCTX) {} { L ERR_CTX } }
  if {[info exists ::env(EDOS)]} { debug set_bp $::env(EDOS) {} { L [format "E_DOS A=%02X" [reg A]] } }
}
after time 28 { type "ICITY\r" }
after time 52 { key 8 0x01 }              ; # "save point"
after time 55 { key 8 0x40 }
after time 56 { key 8 0x40 }
after time 57 { key 8 0x40 }              ; # Quick, SRAM, disk 1, user disk
after time 59 { key 8 0x01 }
set t 68
for {set i 2} {$i <= $::env(SLOT)} {incr i} { after time $t { key 8 0x40 }; incr t }
after time 76 { key 8 0x01 }
for {set t 95} {$t <= 220} {incr t 9} { after time $t {key 8 0x01} }
foreach t {66 78 90 110 140 180 220} { after time $t "screenshot -raw $::T/s_$t.png" }
after time 221 { L "hooks=$::nh violations=$::viol"; close $::lg; exit }
