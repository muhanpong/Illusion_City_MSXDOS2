# font.tcl - check the cartridge glyph fetch (patch G1 -> E980h) against the font file, and that the
# machine's Kanji ROM ports (D8h-DBh) are never written after boot.
# env: T (output dir), END (seconds), FONT (font file), SEQ / SP0 (keys, as verify.tcl)
set throttle off
set ::T $::env(T); set ::END $::env(END)
set ::log [open "$::T/font.log" w]
proc ts {} { format %.2f [machine_info time] }
proc L {m} { puts $::log "[ts] $m"; flush $::log }
set f [open $::env(FONT) rb]; set ::font [read $f]; close $f
set ::n 0; set ::bad 0; set ::kp 0
array set ::uniq {}
proc on_glyph {} {
  set hl [reg HL]; set h [expr {(($hl * 4) >> 8) & 0xFF}]; set l [expr {$hl & 0xFF}]
  set ::idx [expr {(($h & 0x7F) << 6) | ($l & 0x3F)}]
  set ::gbp [debug set_bp [peek16 [reg SP]] {} { gcheck }]
}
proc gcheck {} {
  debug remove_bp $::gbp
  incr ::n; set ::uniq($::idx) 1
  set want [string range $::font [expr {$::idx*32}] [expr {$::idx*32+31}]]
  if {$want ne [debug read_block memory 0xD500 32]} { incr ::bad; if {$::bad < 10} { L [format "MISMATCH idx %04X" $::idx] } }
}
debug set_bp 0xE980 {[pc_in_slot 3 0]} on_glyph
debug set_watchpoint write_io {0xD8 0xDB} {[machine_info time] > 6} { incr ::kp }
proc key {row mask} { keymatrixdown $row $mask ; after time 0.2 "keymatrixup $row $mask" }
foreach {t k} $::env(SEQ) { if {$k eq "d"} { after time $t {key 8 0x40} } else { after time $t {key 8 0x01} } }
for {set t $::env(SP0)} {$t <= $::END} {incr t 6} { after time $t {key 8 0x01} }
for {set t 40} {$t <= $::END} {incr t 40} { after time $t "screenshot -raw $::T/f_$t.png" }
after time $::END { L "glyphs=$::n distinct=[array size ::uniq] bad=$::bad kanji_port_writes=$::kp"; exit }
