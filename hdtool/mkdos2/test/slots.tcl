# slots.tcl - paged save list (patches P1-P6, 96 slots per disk) on the DOS2 build, two runs on the same HD image:
#   MODE=write: FM, "save point", user disk, page 2 of the slot list; the read of slot 9 (sector 0600h) becomes a
#               write (30h) of the buffer, which still holds slot 8
#   MODE=check: same way to page 2; page 1 = the image's 8 slots, slot 9 = slot 8, slots 10-16 empty (zeros)
# Keys are pressed each time the game enters a menu (file7 3AEFh: sound/main/medium menus, 308Ah: the slot list).
# env: HD, T, MODE, IMG (the user disk as shipped: DU_0578.DAT content = 16 sectors; slots 9+ start as zeros)
set throttle off
hda $::env(HD)
reset
set ::T $::env(T)
set ::log [open "$::T/slots.log" w]
proc L {m} { puts $::log "[format %.2f [machine_info time]] $m"; flush $::log }
set f [open $::env(IMG) rb]; set ::img [read $f]; close $f
proc usec {s} { set b [expr {$s * 512}]; string range $::img $b [expr {$b + 1023}] }
proc gw {} { expr {([debug read ioports 0xFF] & 0x1F) != 0} }   ;# game world: its page 3 is not segment 0
proc key {row mask} { keymatrixdown $row $mask ; after time 0.2 "keymatrixup $row $mask" }
after time 28 { type "ICITY\r" }
# menus by their item table (IX): 8338h sound, 836Eh main, 5C19h medium (Quick/SRAM/disk 1/user disk), 5C86h slot
# list. A menu takes keys only once its text is drawn, so a 2-second tick presses what the current menu needs:
# space (sound: FM, main: "save point"), down until item 4 then space (user disk), right until page 2.
set ::cur 0
proc on_menu {} { set ::cur [reg IX]; L [format "menu IX=%04X" $::cur] }
debug set_bp 0x3AEF {[gw]} on_menu
debug set_bp 0x308A {[gw]} on_menu
proc tick {} {
  switch -- $::cur {
    33592 - 33646 { key 8 0x01 }
    23577 { if {[peek 0x34D2] < 4} { key 8 0x40 } else { key 8 0x01 } }
    23686 { if {[peek 0xE952] == 0} { key 8 0x80 } }
  }
  after time 2 tick
}
after time 30 tick
set ::ok 0; set ::bad 0; set ::done 0
proc on_req {} {
  if {[reg C] != 0x2F || [reg DE] < 0x578} return
  set de [reg DE]
  if {$::env(MODE) eq "write"} {
    if {$de == 0x600 && !$::done} { reg C 0x30; set ::done 1; L "inject: write 0600 from F400"
      set ::rb [debug set_bp [peek16 [reg SP]] {} { debug remove_bp $::rb; L [format "write returned A=%02X" [expr {[reg AF]>>8}]] }] }
    return
  }
  set ::cur $de; set ::rb [debug set_bp [peek16 [reg SP]] {} { check }]
}
proc check {} {
  debug remove_bp $::rb
  if {$::cur < 0x600} { set want [usec [expr {$::cur - 0x578}]] } elseif {$::cur == 0x600} { set want [usec 14] } else { set want [string repeat \x00 1024] }
  if {$want eq [debug read_block memory 0xF400 1024]} { incr ::ok; L [format "slot %04X ok" $::cur] } else { incr ::bad; L [format "slot %04X MISMATCH" $::cur] }
}
debug set_bp 0x0090 {[gw]} on_req
after time $::env(END) { screenshot -raw $::T/end.png; L "$::env(MODE) ok=$::ok bad=$::bad"; exit }
