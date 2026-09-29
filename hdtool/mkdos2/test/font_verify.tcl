# Own-font test: every glyph the game requests (wrapper E980h, function 50h) is compared with KANJI.rom at the same address.
# Run on the stock (Japanese) GT: machine Panasonic_FS-A1GT.  Must end with mismatches=0.
# env: HD (image built with FONT=...), T (out dir), KANJI (KANJI.rom), RETADDR=0xE9A3 (the wrapper's 'LD HL,D520h': see icity.lst, glyph_wrap + 23h)
set throttle off
set firmwareswitch off
hda $::env(HD)
reset
set ::lg [open "$::env(T)/log.txt" w]
proc L {m} { puts $::lg "[format %.2f [machine_info time]] $m"; flush $::lg }
proc key {row mask} { keymatrixdown $row $mask ; after time 0.2 "keymatrixup $row $mask" }
set ::rom [open "$::env(KANJI)" rb]; fconfigure $::rom -translation binary
set ::fontdata [read $::rom]; close $::rom
set ::n 0; set ::bad 0; set ::hl 0
array set ::uniq {}
proc at_entry {} { set ::hl [reg HL]; incr ::ne; set ::last [format "entry#%d HL=%04X" $::ne [reg HL]] }
set ::ne 0; set ::last none
proc at_ret {} {
  # entry HL = glyph code as the game passed it (before the wrapper's shifts); redo the original's address math
  set hl $::hl
  set l [expr {$hl & 0xFF}]
  set h [expr {(($hl << 2) >> 8) & 0xFF}]
  set lo [expr {$l & 0x3F}]; set hi [expr {$h & 0x3F}]
  set idx [expr {($hi << 6) | $lo}]
  if {$h & 0x40} { set idx [expr {$idx | 0x1000}] }
  set exp [string range $::fontdata [expr {$idx*32}] [expr {$idx*32+31}]]
  binary scan $exp H* e
  binary scan [debug read_block memory 0xD500 32] H* g
  incr ::n
  set ::uniq($idx) 1
  if {$e ne $g} { incr ::bad; if {$::bad <= 5} { L [format "MISMATCH idx=%04X exp=%s got=%s" $idx $e $g] } }
}
after time 27.5 { debug set_bp 0xE980 {} at_entry; debug set_bp $::env(RETADDR) {} at_ret }
after time 28 { type "ICITY\r" }
after time 38 { key 8 0x01 }
after time 41 { key 8 0x40 }
after time 42 { key 8 0x40 }
after time 43 { key 8 0x01 }
for {set t 60} {$t <= 200} {incr t 6} { after time $t {key 8 0x01} }
after time 205 { L "PC=[format %04X [reg PC]] SP=[format %04X [reg SP]] FC-FF=[debug read ioports 0xFC] [debug read ioports 0xFD] [debug read ioports 0xFE] [debug read ioports 0xFF]"; L "last entry: $::last"; L "checked=$::n mismatches=$::bad unique=[array size ::uniq]"; close $::lg; exit }
