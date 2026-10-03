# run.tcl - drive the original-floppy game (any disk set D1..D8 + DU in $D) through its menus; disk swaps are automatic.
# env: T (out dir), D (dir with D1.dsk..D8.dsk, DU.dsk), SONG (extra Tcl sourced after setup: the measurement),
#      SOUND (0 FM, 1 MIDI), MAIN (main menu item: 1 save point/load, 2 opening, 3 start point), MED (load medium:
#      1 Quick, 2 SRAM, 3 disk 1, 4 user disk), SLOT (slot list row 0-7), END (s), WSTART + WANDER (random keys after WSTART).
# The menu routine 3AEFh/308Ah and the item table IX tell which menu is up; 34D2h is the current item.
# example: T=out D=disks SONG=fv.tcl KROM=KANJI.rom SOUND=1 MAIN=3 SLOT=0 END=600 WSTART=9999 \
#   openmsx -machine Panasonic_FS-A1GT -script run.tcl -command "set renderer SDLGL-PP"
# VRAM survey on the original floppy game (kittya). env: T, D (D1..D8, DU), SOUND (0 FM / 1 MIDI), MAIN (main menu item),
# SLOT (user-disk slot 0-7 when MAIN=1), END
set throttle off
set renderer none
set ::T $::env(T)
set ::log [open "$::T/vram.log" w]
proc L {m} { puts $::log "[format %.2f [machine_info time]] $m"; flush $::log }
set ::curdisk 0
proc d {n} { diska "$::env(D)/D$n.dsk"; set ::curdisk $n; L "INSERT $n" }
proc on_bdos {} {
  if {[reg C] != 0x2F || [reg DE] != 0} return
  if {[peek16 [reg SP]] != 0x5BAE} return
  set w [peek 0x5EC0]
  if {$w <= 7} { set want [expr {$w+1}] } elseif {$w == 10} { set want U } else { return }
  if {$want ne $::curdisk} { d $want }
}
debug set_bp 0xF37D {} on_bdos
d 1
set ::sig1 {0xF5}; set ::sig2 {0x47 0x3E}
source $::env(SONG)
proc key {row mask} { keymatrixdown $row $mask ; after time 0.2 "keymatrixup $row $mask" }
set ::cur 0
set ::snd 0
proc on_menu {} { if {[reg IX] == 0x8338 && !$::snd} { set ::snd 1; if {$::env(SOUND)} { after time 8 {key 8 0x40}; after time 10 {key 8 0x01} } else { after time 8 {key 8 0x01} } }
  if {$::cur != [reg IX]} { L [format "menu %04X item=%d" [reg IX] [peek 0x34D2]]; after time 1 "screenshot -raw $::T/menu_[format %04X [reg IX]].png" }; set ::cur [reg IX] }
debug set_bp 0x3AEF {[peek 0x3AEF] != 0} on_menu
debug set_bp 0x308A {} on_menu
proc sel {n} { set i [peek 0x34D2]; if {$i < $n} { key 8 0x40 } elseif {$i > $n} { key 8 0x20 } else { key 8 0x01 } }
proc tick {} {
  switch -- $::cur {
    33640 { sel $::env(MAIN) }
    23577 { sel [expr {[info exists ::env(MED)] ? $::env(MED) : 3}] }
    23686 { sel $::env(SLOT) }
  }
  after time 2 tick
}
after time 20 tick
after time $::env(END) {
  L "end disk=$::curdisk"
  screenshot -raw $::T/end.png
  exit
}
proc wander {} {
  if {[machine_info time] > $::env(WSTART) && [info exists ::env(WANDER)]} {
    set k [lindex {{8 0x01} {8 0x20} {8 0x40} {8 0x10} {8 0x80} {8 0x01} {8 0x80} {8 0x10}} [expr {int(rand()*8)}]]
    key {*}$k
  }
  after time 1.5 wander
}
after time 60 wander
