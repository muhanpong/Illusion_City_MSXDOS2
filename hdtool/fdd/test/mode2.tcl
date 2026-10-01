# mode2.tcl (SONG for run.tcl, floppy build) - at $TRIG s jumps to kernel mode 2 ((0081)=2, PC=E000h): disk 1 file 14,
# the ending intro, loaded at 8000h. Checks every glyph its own reader copy (g14 stub) returns against KANJI.rom.
set f [open $::env(KROM) rb]; set ::krom [read $f]; close $f
set ::ml [open $::env(T)/m2.log w]
proc M {m} { puts $::ml "[format %.2f [machine_info time]] $m"; flush $::ml }
set ::ok 0; set ::bad 0; set ::g14 0; set ::nk 0
# g14 stub: after fetch, "ld hl,86DCh" at E991
debug set_bp 0xE991 {[peek 0xE991] == 0x21 && [peek16 0xE992] == 0x86DC} {
  incr ::g14
  set v [peek16 0xE948]; set h [expr {$v >> 8}]; set l [expr {$v & 0xFF}]
  set idx [expr {(($h & 0x7F) << 6) | ($l & 0x3F)}]
  set want [string range $::krom [expr {$idx*32}] [expr {$idx*32+31}]]
  if {[debug read_block memory 0x86BC 32] eq $want} { incr ::ok } else { incr ::bad; if {$::bad < 10} { M [format "BAD idx=%04X" $idx] } }
}
debug set_watchpoint write_io {0xD8 0xDB} {[machine_info time] > 5} { incr ::nk; if {$::nk < 5} { M [format "kanji port write PC=%04X" [reg PC]] } }
after time $::env(TRIG) {
  M "TRIGGER: mode 2 (file 14 of disk 1)"; poke 0x81 2; poke 0x82 0; reg SP 0xFAF8; reg PC 0xE000
}
foreach t $::env(SHOTS) { after time $t "screenshot -raw $::env(T)/m$t.png" }
after time [expr {$::env(END)-0.5}] { M "g14 calls=$::g14 ok=$::ok bad=$::bad kanjiwrites=$::nk" }
