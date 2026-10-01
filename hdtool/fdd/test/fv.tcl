# fv.tcl (SONG for run.tcl) - floppy font check: every glyph the patched reader returns (stub g7 E96Ch, after the fetch at
# E978h) is compared with KANJI.rom ($KROM); counts Kanji-ROM port writes (D8h-DBh) and g14 calls. Addresses are those of
# the current fdd.asm build (check the stub symbols if fdd.asm changes).
set f [open $::env(KROM) rb]; set ::krom [read $f]; close $f
set ::fl [open "$::T/fv.log" w]
proc F {m} { puts $::fl "[format %.2f [machine_info time]] $m"; flush $::fl }
set ::ok 0; set ::bad 0; set ::nk 0; set ::n14 0
debug set_bp 0xE978 {[peek 0xE978] == 0x21 && [peek16 0xE979] == 0xD520} {
  set v [peek16 0xE948]; set h [expr {$v >> 8}]; set l [expr {$v & 0xFF}]
  set idx [expr {(($h & 0x7F) << 6) | ($l & 0x3F)}]
  set want [string range $::krom [expr {$idx*32}] [expr {$idx*32+31}]]
  if {[debug read_block memory 0xD500 32] eq $want} { incr ::ok } else { incr ::bad; if {$::bad < 20} { F [format "BAD idx=%04X" $idx] } }
}
debug set_bp 0xE985 {[peek 0xE985] == 0x3A} { incr ::n14; if {$::n14 < 5} { F "g14 called" } }
debug set_watchpoint write_io {0xD8 0xDB} {[machine_info time] > 5} { incr ::nk; if {$::nk < 5} { F [format "kanji port write PC=%04X" [reg PC]] } }
after time 30 { F "FLAG=[peek 0xE947]" }
after time [expr {$::env(END)-0.5}] { F "glyphs ok=$::ok bad=$::bad kanjiwrites=$::nk g14=$::n14 FLAG=[peek 0xE947]" }
foreach t {120 300 500} { after time $t "screenshot -raw $::T/s$t.png" }
debug set_bp 0x4133 {[peek 0x4133] == 0x22} { set f [open $::T/fv_cache.log a]; puts $f [format "t=%.1f set size HL=%04X start(432E)=%04X FD=%02X" [machine_info time] [reg HL] [peek16 0x432E] [expr {[debug read ioports 0xFD]&0x1F}]]; close $f }
