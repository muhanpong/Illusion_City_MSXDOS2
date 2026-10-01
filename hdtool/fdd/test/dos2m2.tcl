# dos2m2.tcl - DOS2 build (hda image, Nextor): boots, runs ICITY, forces kernel mode 2 (ending intro, disk 1 file 14) from
# the main menu and checks each glyph the patched ADFEh routine (G2) leaves at 86BCh against KANJI.rom; counts port writes.
# env: HD, T, KROM, SHOTS, END
set throttle off
hda $::env(HD)
reset
set f [open $::env(KROM) rb]; set ::krom [read $f]; close $f
set ::ml [open $::env(T)/m2.log w]
proc M {m} { puts $::ml "[format %.2f [machine_info time]] $m"; flush $::ml }
proc gw {} { expr {([debug read ioports 0xFF] & 0x1F) != 0} }
after time 28 { type "ICITY\r" }
set ::ok 0; set ::bad 0; set ::calls 0; set ::nk 0; set ::trig 0; set ::idx -1
# patched routine entry (page 2 must hold file 14: patched bytes CD xx E9)
debug set_bp 0xADFE {[peek 0xADFE] == 0xCD && [peek 0xAE00] == 0xE9} {
  incr ::calls
  set hl [reg HL]; set h2 [expr {(($hl << 2) >> 8) & 0xFF}]; set l [expr {$hl & 0xFF}]
  set ::idx [expr {(($h2 & 0x7F) << 6) | ($l & 0x3F)}]
}
# back in the caller after the glyph routine returned
debug set_bp 0xADC9 {[peek 0xADC6] == 0xCD && [peek16 0xADC7] == 0xADFE && $::idx >= 0} {
  set want [string range $::krom [expr {$::idx*32}] [expr {$::idx*32+31}]]
  if {[debug read_block memory 0x86BC 32] eq $want} { incr ::ok } else { incr ::bad; if {$::bad < 10} { M [format "BAD idx=%04X" $::idx] } }
  set ::idx -1
}
debug set_watchpoint write_io {0xD8 0xDB} {[machine_info time] > 5} { incr ::nk; if {$::nk < 5} { M [format "kanji port write PC=%04X" [reg PC]] } }
debug set_bp 0x3AEF {[gw] && [reg IX] == 0x836E && !$::trig} { set ::trig 1; after time 4 { M "TRIGGER mode 2"; poke 0x81 2; poke 0x82 0; reg SP 0xFAF8; reg PC 0xE000 } }
proc key {row mask} { keymatrixdown $row $mask ; after time 0.2 "keymatrixup $row $mask" }
set ::cur 0
debug set_bp 0x3AEF {[gw]} { set ::cur [reg IX] }
proc tick { } { if {$::cur == 33592} { key 8 0x01 }; after time 2 tick }
after time 30 tick
foreach t $::env(SHOTS) { after time $t "screenshot -raw $::env(T)/m$t.png" }
after time [expr {$::env(END)-0.5}] { M "calls=$::calls verified ok=$::ok bad=$::bad kanjiwrites=$::nk" }
after time $::env(END) { exit }
