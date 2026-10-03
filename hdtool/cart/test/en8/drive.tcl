# English 8-disc cartridge test driver (headless openMSX, Panasonic_FS-A1GT, no disk): the ROM boots by itself.
# run: T=out IMG=all9.dsk MAIN=1 MED=4 SLOT=1 SOUND=0 END=200 openmsx -machine Panasonic_FS-A1GT -carta ICITY_A16X.rom [-romtype Yamanooto] -script drive.tcl
# (IMG = DUMP_DATA=all9.dsk python3 mkcart.py <disks> <user disk> - <out>).  env also: NOSLOT=1, KEYS="t:row:mask ...", DUMPS, WW=1 (log game writes into the
# cartridge's page-3/page-0 areas into viol.txt), INJ (1024 bytes) + INJSEC (default 057Ah): turn the first user-disk slot read into a write.
# The driver ends openMSX with SIGTERM (flash writes are saved to ~/.openMSX/persistent/roms/<rom name>/ on a normal exit); use a ROM file name of its own for write tests.
# out: log.txt, reads.log, midi.txt, viol.txt, samp.txt, v<t>.bin/.txt
# Drives the menus by menu IX like drive.tcl, logs every F37D 2Fh/30h (reads.log), checks every read's data against IMG
# (the 9 disks back to back as the ROM serves them: mkcart DUMP_DATA) and dumps VRAM.
# env: T (out), IMG, MAIN MED SLOT SOUND END DUMPS KEYS NOSLOT
set throttle off
set renderer none
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
set f [open $::env(IMG) rb]; set ::img [read $f]; close $f
set ::dta 0x80; set ::cur_d 1; set ::n 0; set ::bad 0
set ::injdone 0
proc on_bdos {} {
  set c [reg C]
  if {$c == 0x1A} { set ::dta [reg DE]; return }
  if {[info exists ::env(INJ)] && !$::injdone && $c == 0x2F && [reg DE] == 0x578 && [peek 0x5EC0] == 0x0A} {
    set ::injdone 1
    set f [open $::env(INJ) rb]; set d [read $f]; close $f
    for {set i 0} {$i < 1024} {incr i} { poke [expr {$::dta+$i}] [scan [string index $d $i] %c] }
    L [format "INJECT: slot data -> DTA %04X, write to sector %04X" $::dta [expr {[info exists ::env(INJSEC)] ? $::env(INJSEC) : 0x57A}]]
    reg C 0x30
    reg DE [expr {[info exists ::env(INJSEC)] ? $::env(INJSEC) : 0x57A}]
    set ::rb [debug set_bp [peek16 [reg SP]] {} { debug remove_bp $::rb; L [format "write returned A=%02X" [expr {[reg AF]>>8}]] }]
  }
  if {$c != 0x2F && $c != 0x30} { L [format "BDOS C=%02X" $c]; return }
  set de [reg DE]; set cnt [expr {[reg HL] >> 8}]
  puts $::rl [format "%.2f %02X %04X %02X A8=%02X ret=%04X" [machine_info time] $c $de $cnt [debug read ioports 0xA8] [peek16 [reg SP]]]; flush $::rl
  if {$c == 0x30} return
  if {$de == 0} { set w [peek 0x5EC0]; L [format "disk check (5EC0)=%02X" $w]; if {$w <= 7} { set ::cur_d [expr {$w+1}] } elseif {$w == 10} { set ::cur_d 9 } }
  if {$de >= 0x578 && $de < 0x588 && $::cur_d != 1 && $::cur_d != 9} {} 
  set ret [peek16 [reg SP]]
  set ::pend [list $::dta $::cur_d $de $cnt]
  set ::bpid [debug set_bp $ret {} { check }]
}
proc check {} {
  foreach {dta cur de cnt} $::pend break
  debug remove_bp $::bpid
  if {$de >= 0x578 && ($cur == 1 || $cur == 9)} return
  set off [expr {(($cur-1)*1440 + $de)*512}]
  set len [expr {$cnt*512}]
  set want [string range $::img $off [expr {$off+$len-1}]]
  set got [debug read_block memory $dta $len]
  incr ::n
  if {$want ne $got} { incr ::bad; set i 0; while {[string index $want $i] eq [string index $got $i]} { incr i }
    L [format "MISMATCH disk %d sec %04X cnt %d dta %04X first diff at +%X A8=%02X FD=%02X FE=%02X got=%s want=%s" $cur $de $cnt $dta $i [debug read ioports 0xA8] [debug read ioports 0xFD] [debug read ioports 0xFE] [binary encode hex [string range $got $i [expr {$i+7}]]] [binary encode hex [string range $want $i [expr {$i+7}]]]] }
}
set ::mf [open "$::T/midi.txt" w]
set ::nm 0
proc on_midi {} { if {$::wp_last_value != 0 && $::nm < 6000} { puts $::mf [format "%02X %02X" [expr {$::wp_last_address & 0xFF}] $::wp_last_value]; incr ::nm; if {$::nm % 50 == 0} { flush $::mf } } }
debug set_watchpoint write_io {0xE8 0xE9} {} on_midi
set ::vl [open "$::T/viol.txt" w]
array set ::vseen {}
set ::cartreg {{0xDD92 0xDF7D} {0xE96F 0xEDDF} {0xEF80 0xF139} {0xF13A 0xF16A} {0xF176 0xF277} {0xF27F 0xF323} {0xF325 0xF341} {0x0000 0x0054} {0x0080 0x0087}}
proc incart {pc} { foreach r $::cartreg { if {$pc >= [lindex $r 0] && $pc <= [lindex $r 1]} { return 1 } }; return 0 }
proc on_cw {} {
  set a $::wp_last_address
  if {[info exists ::vseen($a)]} return
  set pc [reg PC]
  if {[incart $pc]} return
  set pg [expr {$pc >> 14}]
  set slot [expr {([debug read ioports 0xA8] >> (2*$pg)) & 3}]
  if {$slot != 3} return
  set ::vseen($a) 1
  puts $::vl [format "%.2f W %04X=%02X PC=%04X" [machine_info time] $a $::wp_last_value $pc]; flush $::vl
}
if {[info exists ::env(WW)]} { foreach r $::cartreg { debug set_watchpoint write_mem $r {} on_cw } }
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
debug set_bp 0xF37D {} on_bdos
debug set_bp 0x3AEF {[peek 0x3AEF] != 0} on_menu
debug set_bp 0x308A {} on_menu
after time 8 tick
if {[info exists ::env(KEYS)]} { foreach k $::env(KEYS) { lassign [split $k :] t row mask; after time $t "key $row $mask" } }
foreach t $::env(DUMPS) { after time $t "dumpv $t" }
set ::sl [open "$::T/samp.txt" w]
set ::sk 0
proc smp {} { if {$::sk < 40} { incr ::sk; puts $::sl [format "%.3f PC=%04X SP=%04X A8=%02X mem=%s" [machine_info time] [reg PC] [reg SP] [debug read ioports 0xA8] [binary encode hex [debug read_block memory 0xE750 16]]]; flush $::sl }; after time 0.05 smp }
after time [expr {$::env(END)-5}] smp
array set ::hc {}
foreach a {0xE69B 0xE6B9 0xE6C5 0xE6D5 0xE741 0xE507 0xE60A 0xE6DB} { set ::hc($a) 0; debug set_bp $a {[machine_info time] > 40} "incr ::hc($a)" }
after time [expr {$::env(END)-1}] { set f [open "$::T/hc.txt" w]; foreach a [lsort [array names ::hc]] { puts $f "$a $::hc($a)" }; close $f }
set ::tl [open "$::T/e507.txt" w]
set ::tk 0
debug set_bp 0xE519 {[machine_info time] > 50} { if {$::tk < 12} { incr ::tk; puts $::tl [format "E519 A=%02X BC=%04X DE=%04X HL=%04X (0083)=%02X %02X" [reg A] [reg BC] [reg DE] [reg HL] [peek 0x83] [peek 0x84]]; flush $::tl } }
after time $::env(END) { L "end reads=$::n bad=$::bad PC=[format %04X [reg PC]]"; close $::rl; close $::lg; close $::mf; close $::vl; exec kill -TERM [pid] }
set f [open "$::env(T)/vdp.txt" w]
proc dump {tag} { global f
  set r {}; for {set i 32} {$i <= 46} {incr i} { lappend r [format %02X [vdpreg $i]] }
  set s {}; foreach i {0 1 2 3 4 5 6 7 8 9} { lappend s [format %02X [debug read "VDP status regs" $i]] }
  puts $f "$tag t=[machine_info time] R32-46=$r S0-9=$s PC=[format %04X [reg PC]]"; flush $f }
after time [expr {$::env(END)-2}] { dump A; after time 1 { dump B } }
