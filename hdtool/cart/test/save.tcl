# save.tcl - save write path, two openMSX runs (the flash persists in ~/.openMSX/persistent/roms/<rom>/):
#   MODE=write: open the user-disk load list and turn its read of slot 2 (057Ah) into a write (30h) of the
#               buffer, which still holds slot 1
#   MODE=check: open the list again and compare all 8 user-disk slots: slot 2 = slot 1, the others unchanged
# env: T (output dir), MODE, IMG (disks 1-8 + user disk, 9 x 720KB, the ROM's initial content)
# Delete the .SRAM file afterwards to get the ROM's own saves back.
set throttle off
set ::T $::env(T)
set ::log [open "$::T/save.log" w]
proc ts {} { format %.2f [machine_info time] }
proc L {m} { puts $::log "[ts] $m"; flush $::log }
set f [open $::env(IMG) rb]; set ::img [read $f]; close $f
proc usec {s} { string range $::img [expr {(8*1440 + $s)*512}] [expr {(8*1440 + $s)*512 + 1023}] }
proc key {row mask} { keymatrixdown $row $mask ; after time 0.2 "keymatrixup $row $mask" }
proc menus {t0} { foreach {t k} {41 s 76 s 96 d 97 d 98 d 99 s} { set at [expr {$t0 + $t}]
  if {$k eq "d"} { after time $at {key 8 0x40} } else { after time $at {key 8 0x01} } } }
set ::phase [expr {$::env(MODE) eq "write" ? 1 : 3}]; set ::ok 0; set ::bad 0
proc on_bdos {} {
  if {[reg C] != 0x2F} return
  set de [reg DE]
  if {$de < 0x578 || $de > 0x586 || [peek 0x5EC0] != 10} return
  if {$::phase == 1 && $de == 0x57A} {
    reg C 0x30; set ::phase 2; L "inject: write slot 2 (057A) from F400"
    set ::rb [debug set_bp [peek16 [reg SP]] {} { debug remove_bp $::rb; L [format "write returned A=%02X" [expr {[reg AF]>>8}]] }]
    return
  }
  if {$::phase == 3} { set ::cur $de; set ::rb [debug set_bp [peek16 [reg SP]] {} { check }] }
}
proc check {} {
  debug remove_bp $::rb
  set want [usec [expr {$::cur == 0x57A ? 0x578 : $::cur}]]
  set got [debug read_block memory 0xF400 1024]
  if {$want eq $got} { incr ::ok; L [format "slot %04X ok" $::cur] } else { incr ::bad; L [format "slot %04X MISMATCH" $::cur] }
}
debug set_bp 0xF37D {} on_bdos
menus 0
if {$::phase == 1} {
  after time 110 { L "write phase=$::phase"; exit }
} else {
  after time 128 { screenshot -raw $::T/list.png; L "check ok=$::ok bad=$::bad"; exit }
}
