# save2.tcl - extended slots (page 2 of the user-disk list), two openMSX runs (flash persists between them):
#   MODE=write: open the list, go to page 2 and turn the read of slot 9 (sector 0600h) into a write (30h) of the
#               buffer, which still holds slot 8 (same flash group as slots 1-8: exercises the group copy)
#   MODE=check: page 1 = the ROM's 8 slots, page 2 slot 9 = slot 8, slots 10-16 empty (FFh)
# env: T, MODE, IMG (disks 1-8 + user disk as in the ROM); optional WSEC (sector to write, default 0600h) and
#      DISK (1 = the disk-1 list, default 9 = user disk), EXP ("sector:source ...", what page 1/2 sectors must hold beyond the ROM's slots; default "0600:0586")
set throttle off
set ::T $::env(T)
set ::log [open "$::T/save2.log" w]
proc L {m} { puts $::log "[format %.2f [machine_info time]] $m"; flush $::log }
set f [open $::env(IMG) rb]; set ::img [read $f]; close $f
set ::disk [expr {[info exists ::env(DISK)] ? $::env(DISK) : 9}]
proc usec {s} { set b [expr {(($::disk - 1)*1440 + $s)*512}]; string range $::img $b [expr {$b + 1023}] }
proc key {row mask} { keymatrixdown $row $mask ; after time 0.2 "keymatrixup $row $mask" }
set ::keys [expr {$::disk == 1 ? {41 8 0x01 76 8 0x01 96 8 0x40 97 8 0x40 99 8 0x01 128 8 0x80} : {41 8 0x01 76 8 0x01 96 8 0x40 97 8 0x40 98 8 0x40 99 8 0x01 128 8 0x80}}]
foreach {t r m} $::keys { after time $t "key $r $m" }
set ::ok 0; set ::bad 0; set ::done 0
set ::wsec [expr {[info exists ::env(WSEC)] ? "0x$::env(WSEC)" : 0x600}]
array set ::exp {}
foreach e [expr {[info exists ::env(EXP)] ? $::env(EXP) : "0600:0586"}] { lassign [split $e :] a b; set ::exp([expr {"0x$a"}]) [expr {"0x$b"}] }
proc on_bdos {} {
  if {[reg C] != 0x2F || [peek 0x5EC0] != ($::disk == 1 ? 0 : 10)} return
  set de [reg DE]
  if {$de < 0x578} return
  if {$::env(MODE) eq "write"} {
    if {$de == $::wsec && !$::done} { reg C 0x30; set ::done 1; L [format "inject: write %04X from F400" $de]
      set ::rb [debug set_bp [peek16 [reg SP]] {} { debug remove_bp $::rb; L [format "write returned A=%02X" [expr {[reg AF]>>8}]] }] }
    return
  }
  set ::cur $de; set ::rb [debug set_bp [peek16 [reg SP]] {} { check }]
}
proc check {} {
  debug remove_bp $::rb
  if {[info exists ::exp($::cur)]} { set want [usec $::exp($::cur)] } elseif {$::cur < 0x600} { set want [usec $::cur] } else { set want [string repeat \xFF 1024] }
  if {$want eq [debug read_block memory 0xF400 1024]} { incr ::ok; L [format "slot %04X ok" $::cur] } else { incr ::bad; L [format "slot %04X MISMATCH" $::cur] }
}
debug set_bp 0xF37D {} on_bdos
after time 138 { screenshot -raw $::T/page2.png; L "[expr {$::env(MODE) eq {write} ? {write} : {check}}] ok=$::ok bad=$::bad"; exit }
