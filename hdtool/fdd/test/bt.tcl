# bt.tcl - boot timeline of a disk 1 image ($D1): loader start, font load (floppy build), kernel, menus, sector counts.
set throttle off
diska $::env(D1)
set ::f [open $::env(T)/bt.log w]
proc L {m} { puts $::f [format "%7.2f %s" [machine_info time] $m]; flush $::f }
proc once {name addr cond} { set ::o($name) [debug set_bp $addr $cond "L $name; debug remove_bp \$::o($name)"] }
once fray_start 0x0100 {[peek 0x0100] == 0x21 && [peek16 0x0101] == 0x045B}
once init 0x0E20 {[peek 0x0E20] == 0x3A && [peek16 0x0E21] == 0xE8F3}
once kernel 0xE000 {[peek 0xE000] == 0xC3 && [peek16 0xE001] == 0xE04B}
set ::nr 0; set ::ns 0; set ::fontr 0
debug set_bp 0xF37D {[reg C] == 0x2F} { incr ::nr; set ::ns [expr {$::ns + [reg H]}]; if {[reg DE] >= 0x550 && [reg DE] < 0x578} { L [format "font read DE=%04X n=%d" [reg DE] [reg H]] } }
set ::m 0
debug set_bp 0x3AEF {} { if {[reg IX] != $::m} { set ::m [reg IX]; L [format "menu IX=%04X reads=%d sectors=%d" [reg IX] $::nr $::ns] } }
after time 90 { L "end reads=$::nr sectors=$::ns"; close $::f; exit }
