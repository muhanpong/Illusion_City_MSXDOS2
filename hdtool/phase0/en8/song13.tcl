source $::env(S)/song11b.tcl
source $::env(S)/bot.tcl
foreach k $::env(KEYS) { lassign [split $k :] t row mask; after time $t "key $row $mask" }
foreach t $::env(DUMPS) { after time $t "dumpv $t" }
set ::wl [open "$::T/s1.log" w]
proc W {m} { puts $::wl "[format %.2f [machine_info time]] $m"; flush $::wl }
proc on_f {} { set c [reg C]; if {$c == 0x2F && [reg DE] > 0x100 && [reg DE] < 0x578} { return }; W [format "BDOS C=%02X DE=%04X HL=%04X ret=%04X d=%d" $c [reg DE] [reg HL] [peek16 [reg SP]] $::curdisk] }
debug set_bp 0xF37D {} on_f
