# openMSX test: boot Nextor HD, run ICITY, choose "start point", follow the opening dialog.
# env: HD (hd image), T (output dir), optional ERRCTX/EDOS (launcher error label addresses from icity.lst)
# run: HD=... T=... openmsx -machine kittyk -ext SunriseIDE_Nextor -script start_disk2.tcl
set throttle off
set firmwareswitch off
hda $::env(HD)
reset
set ::T $::env(T)
set ::lg [open "$::T/log.txt" w]
proc L {m} { puts $::lg "[format %.2f [machine_info time]] $m"; flush $::lg }
proc key {row mask} { keymatrixdown $row $mask ; after time 0.2 "keymatrixup $row $mask" }
set ::nh 0
proc on_hook {} { incr ::nh; if {[reg C]==0x2F && ([reg DE]==0 || $::nh<=6)} { L [format "HOOK C=%02X DE=%04X HL=%04X ret=%04X 5EC0=%02X" [reg C] [reg DE] [reg HL] [peek16 [reg SP]] [peek 0x5EC0]] } }
# mapper writes from the game environment must stay inside the launcher's allocation (04h.. on a fresh Nextor boot)
array set ::seen {}
set ::viol 0
proc on_map {} {
  set pc [reg PC]; set v [expr {$::wp_last_value & 0x1F}]
  if {$pc >= 0xE000 && $pc < 0xEA00 && ($v < 4 || $v > 0x18)} { incr ::viol; if {$::viol < 10} { L [format "VIOLATION port %02X=%02X PC=%04X" [expr {$::wp_last_address & 0xFF}] $::wp_last_value $pc] } }
  set k "[format %02X [expr {$::wp_last_address & 0xFF}]]=[format %02X $v]"
  if {![info exists ::seen($k)]} { set ::seen($k) 1 }
}
after time 27.5 {
  debug set_bp 0x0090 {([debug read ioports 0xFC] & 0x1F) != 3} on_hook
  debug set_watchpoint write_io {0xFC 0xFF} {} on_map
  if {[info exists ::env(ERRCTX)]} { debug set_bp $::env(ERRCTX) {} { L ERR_CTX } }
  if {[info exists ::env(EDOS)]} { debug set_bp $::env(EDOS) {} { L [format "E_DOS A=%02X" [reg A]] } }
}
after time 28 { type "ICITY\r" }
after time 52 { key 8 0x40 }
after time 53 { key 8 0x40 }
after time 54 { key 8 0x01 }
for {set t 66} {$t <= 300} {incr t 6} { after time $t {key 8 0x01} }
foreach t {50 62 80 100 120 140 160 180 200 240 280 300} { after time $t "screenshot -raw $::T/s_$t.png" }
after time 301 { L "hooks=$::nh violations=$::viol mapper values: [lsort [array names ::seen]]"; close $::lg; exit }
