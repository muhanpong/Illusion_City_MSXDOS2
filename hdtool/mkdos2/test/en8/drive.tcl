# English 8-disc DOS2 build driver (headless openMSX, Panasonic_FS-A1GT + Nextor/SunriseIDE or -ext ide): boot Nextor HD, run ICITY, drive the menus like fdd/test/run.tcl (menu IX + item at 34D2h),
# log every F37D request (sector reads) to reads.log, dump VRAM at DUMPS.
# env: HD (hd image) T (out dir) MAIN (main menu item: 1 load, 2 opening demo, 3 start point) MED (load medium: 4 user disk)
#      SLOT (1-8) SOUND (0 FM / 1 MIDI) END (s) DUMPS (VRAM dump times) KEYS ("t:row:mask ...", extra key presses, e.g. 52:8:0x80 = right at t=52)
#      NOSLOT=1 (do not pick a slot automatically) INJ (file with 1024 bytes: turns the first user-disk slot read into a write of this to sector INJSEC, default 57Ah)
# out: log.txt, reads.log (time fn sector count of every F37D 2Fh/30h), midi.txt (first 6000 non-zero MSX-MIDI bytes), v<t>.bin/.txt (VRAM + registers)
# The hook breakpoint is E999h (icity.asm EN8: HOOKA); the driver kills openMSX at END (a plain exit can hang headless).
set throttle off
set renderer none
set firmwareswitch off
hda $::env(HD)
reset
set ::T $::env(T)
set ::lg [open "$::T/log.txt" w]
set ::rl [open "$::T/reads.log" w]
proc L {m} { puts $::lg "[format %.2f [machine_info time]] $m"; flush $::lg }
proc key {row mask} { keymatrixdown $row $mask ; after time 0.2 "keymatrixup $row $mask" }
proc dumpv {tag} {
  set f [open "$::T/v$tag.bin" wb]; fconfigure $f -translation binary; puts -nonewline $f [debug read_block VRAM 0 131072]; close $f
  set f [open "$::T/v$tag.txt" w]
  set r {}; for {set i 0} {$i < 28} {incr i} { lappend r [vdpreg $i] }
  set c {}; for {set i 0} {$i < 16} {incr i} { lappend c [getcolor $i] }
  puts $f "regs $r"; puts $f "colors $c"; close $f }
set ::nh 0
set ::injdone 0
proc on_hook {} { incr ::nh
  if {[info exists ::env(INJ)] && !$::injdone && [reg C] == 0x2F && [reg DE] == 0x578 && [peek 0x5EC0] == 0x0A} {
    set ::injdone 1
    set dta [peek16 0xE972]
    set f [open "$::env(INJ)" rb]; set d [read $f]; close $f
    for {set i 0} {$i < 1024} {incr i} { poke [expr {$dta+$i}] [scan [string index $d $i] %c] }
    L [format "INJECT: slot data -> DTA %04X, write to sector 057A (was 2Fh DE=0578)" $dta]
    reg C 0x30
    reg DE [expr {[info exists ::env(INJSEC)] ? $::env(INJSEC) : 0x057A}]
  }
  set c [reg C]
  if {$c == 0x2F || $c == 0x30} { puts $::rl [format "%.2f %02X %04X %02X" [machine_info time] $c [reg DE] [reg H]]; flush $::rl }
  if {$c == 0x2F && [reg DE] == 0} { L [format "disk check (5EC0)=%02X" [peek 0x5EC0]] } }
set ::cur 0
set ::snd 0
proc on_menu {} {
  if {[reg IX] == 0x8338 && !$::snd} { set ::snd 1; if {$::env(SOUND)} { after time 8 {key 8 0x40}; after time 10 {key 8 0x01} } else { after time 8 {key 8 0x01} } }
  if {$::cur != [reg IX]} { L [format "menu %04X item=%d" [reg IX] [peek 0x34D2]]; after time 1 "dumpv m[format %04X [reg IX]]" }; set ::cur [reg IX] }
proc sel {n} { set i [peek 0x34D2]; if {$i < $n} { key 8 0x40 } elseif {$i > $n} { key 8 0x20 } else { key 8 0x01 } }
proc tick {} {
  switch -- $::cur {
    33640 { sel $::env(MAIN) }
    23577 { sel $::env(MED) }
    23686 { if {![info exists ::env(NOSLOT)]} { sel $::env(SLOT) } }
  }
  after time 2 tick
}
after time 27.5 {
  debug set_bp 0xE999 {([debug read ioports 0xFC] & 0x1F) != 3} on_hook
  debug set_bp 0x3AEF {[peek 0x3AEF] != 0} on_menu
  debug set_bp 0x308A {} on_menu
}
set ::mf [open "$::T/midi.txt" w]
set ::nm 0
proc on_midi {} { if {$::wp_last_value != 0 && $::nm < 6000} { puts $::mf [format "%02X %02X" [expr {$::wp_last_address & 0xFF}] $::wp_last_value]; incr ::nm; if {$::nm % 50 == 0} { flush $::mf } } }
after time 27.5 { debug set_watchpoint write_io {0xE8 0xE9} {} on_midi }
after time 28 { type "ICITY\r" }
after time 33 tick
if {[info exists ::env(KEYS)]} { foreach k $::env(KEYS) { lassign [split $k :] t row mask; after time $t "key $row $mask" } }
foreach t $::env(DUMPS) { after time $t "dumpv $t" }
after time $::env(END) { L "end hooks=$::nh PC=[format %04X [reg PC]]"; close $::rl; close $::lg; close $::mf; exec kill -9 [pid] }
