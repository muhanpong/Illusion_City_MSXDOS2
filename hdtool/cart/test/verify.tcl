# verify.tcl - run the cartridge ROM and check every F37D 2Fh read against the disk images.
# env: T (output dir), END (seconds), IMG (disks 1-8 + user disk back to back, 9 x 720KB),
#      SEQ ("time key ..." with key d = down, s = space), SP0 (space every 6 s from here)
# log: $T/verify.log ("ok"/"MISMATCH" per read, last line reads=N bad=M), screenshots $T/v_*.png
# example (start point, FM):
#   T=out END=400 SEQ="41 s 76 d 77 d 78 s" SP0=90 IMG=all9.dsk SDL_VIDEODRIVER=offscreen \
#   openmsx -machine kittya -carta ICITY_YAMA.rom -romtype Yamanooto -command "set renderer SDLGL-PP" \
#           -command "set firmwareswitch off" -script verify.tcl
# MIDI: SEQ="41 d 42 s 76 d 77 d 78 s". Load user-disk save 8: SEQ="41 s 76 s 96 d 97 d 98 d 99 s
#   128 d 129 d 130 d 131 d 132 d 133 d 134 d 135 s" SP0=150. Menus take keys only once the cursor shows.
set throttle off
set ::T $::env(T); set ::END $::env(END)
set ::log [open "$::T/verify.log" w]
proc ts {} { format %.2f [machine_info time] }
proc L {m} { puts $::log "[ts] $m"; flush $::log }
set f [open $::env(IMG) rb]; set ::img [read $f]; close $f
set ::dta 0x80; set ::cur 1; set ::n 0; set ::bad 0
proc on_bdos {} {
  if {[reg C] == 0x1A} { set ::dta [reg DE]; return }
  if {[reg C] != 0x2F} { L [format "BDOS C=%02X" [reg C]]; return }
  set de [reg DE]; set cnt [expr {[reg HL] >> 8}]
  if {$de == 0} { set w [peek 0x5EC0]; if {$w <= 7} { set ::cur [expr {$w+1}] } elseif {$w == 10} { set ::cur 9 } }
  set ret [peek16 [reg SP]]
  set ::pend [list $::dta $::cur $de $cnt]
  set ::bpid [debug set_bp $ret {} { check }]
}
proc check {} {
  foreach {dta cur de cnt} $::pend break
  debug remove_bp $::bpid
  set off [expr {(($cur-1)*1440 + $de)*512}]
  set len [expr {$cnt*512}]
  set want [string range $::img $off [expr {$off+$len-1}]]
  set got [debug read_block memory $dta $len]
  incr ::n
  if {$want ne $got} { incr ::bad; set i 0; while {[string index $want $i] eq [string index $got $i]} { incr i }
    L [format "MISMATCH disk %d sec %04X cnt %d dta %04X first diff at +%X" $cur $de $cnt $dta $i] } elseif {$::n < 400} { L [format "ok disk %d sec %04X cnt %d dta %04X" $cur $de $cnt $dta] }
}
debug set_bp 0xF37D {} on_bdos
proc key {row mask} { keymatrixdown $row $mask ; after time 0.2 "keymatrixup $row $mask" }
foreach {t k} $::env(SEQ) { if {$k eq "d"} { after time $t {key 8 0x40} } else { after time $t {key 8 0x01} } }
for {set t $::env(SP0)} {$t <= $::END} {incr t 6} { after time $t {key 8 0x01} }
for {set t 20} {$t <= $::END} {incr t 20} { after time $t "screenshot -raw $::T/v_$t.png" }
after time $::END { L "reads=$::n bad=$::bad"; exit }
