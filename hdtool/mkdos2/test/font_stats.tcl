# Own-font statistics: glyph requests, cache misses (file reads), music sector reads, Kanji-ROM port writes, mapper violations.
# env: HD, T, SND=fm|midi, RG=<hex address of read_glyph from icity.lst>
set throttle off
set firmwareswitch off
hda $::env(HD)
reset
set ::lg [open "$::env(T)/log.txt" w]
proc L {m} { puts $::lg "[format %.2f [machine_info time]] $m"; flush $::lg }
proc key {row mask} { keymatrixdown $row $mask ; after time 0.2 "keymatrixup $row $mask" }
set ::ng 0; set ::nmiss 0; set ::nmus 0; set ::viol 0; set ::nkr 0
proc on_hook {} { if {[reg C]==0x50} { incr ::ng } elseif {[reg C]==0x2F && [reg L]==0x80} { incr ::nmus } }
proc on_miss {} { incr ::nmiss }
proc on_kanji {} { incr ::nkr }
proc on_map {} { set pc [reg PC]; set v [expr {$::wp_last_value & 0x1F}]; if {$pc >= 0xE000 && $pc < 0xEA00 && ($v < 4 || $v > 0x1F)} { incr ::viol } }
after time 27.5 {
  debug set_bp 0x0090 {([debug read ioports 0xFC] & 0x1F) != 3} on_hook
  debug set_bp 0x$::env(RG) {} on_miss
  debug set_watchpoint write_io {0xD8 0xDB} {} on_kanji
  debug set_watchpoint write_io {0xFC 0xFF} {} on_map
}
after time 28 { type "ICITY\r" }
if {$::env(SND) eq "fm"} { after time 38 { key 8 0x01 } } else { after time 36 { key 8 0x40 }; after time 38 { key 8 0x01 } }
after time 41 { key 8 0x40 }
after time 42 { key 8 0x40 }
after time 43 { key 8 0x01 }
for {set t 60} {$t <= 200} {incr t 5} { after time $t {key 8 0x01} }
foreach t {70 100 130 160 200} { after time $t "screenshot -raw $::env(T)/s$t.png" }
after time 205 { L "glyph requests=$::ng  file reads(miss)=$::nmiss  music sector reads=$::nmus  kanji-rom writes=$::nkr  mapper violations=$::viol"; close $::lg; exit }
