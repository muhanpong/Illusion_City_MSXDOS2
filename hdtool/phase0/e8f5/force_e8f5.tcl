# E8F5 force test: original game, MIDI mode, detected mapper size forced to 14h.
# env: ::T (output dir), ::D (disk dir), ::FORCE (hex value or "" for no force)
set throttle off
set ::log [open "$::T/trace.log" w]
array set ::seen {}
array set ::cnt {}
set ::curdisk 1
set ::started 0
set ::over 0
proc ts {} { format %.2f [machine_info time] }
proc L {msg} { puts $::log "[ts] $msg"; flush $::log }
# loader 0114: LD (E8F5),A  -- A = detected mapper segment count
proc on_detect {} {
    if {[peek 0x114] != 0x32 || [peek16 0x115] != 0xE8F5} return
    L "detect A=[format %02X [reg A]]"
    if {$::FORCE ne ""} { reg A $::FORCE; L "forced A=[format %02X [reg A]]" }
}
debug set_bp 0x0114 {} on_detect
proc on_map {} {
    set port [expr {$::wp_last_address & 0xFF}]
    set val  $::wp_last_value
    set pc [reg PC]
    if {$pc >= 0xE000 && $pc < 0xEA00} { set ::started 1 }
    if {!$::started} return
    set k "[format %02X $port]=[format %02X $val]"
    if {![info exists ::seen($k)]} {
        set ::seen($k) 1
        L "NEW P$k PC=[format %04X $pc] disk=$::curdisk"
    }
    if {$::FORCE ne "" && ($val & 0x1F) >= $::FORCE} { incr ::over; if {$::over < 20} { L "OVER P$k PC=[format %04X $pc]" } }
    incr ::cnt($k)
}
debug set_watchpoint write_io {0xFC 0xFF} {} on_map
proc d {n} {
    diska "$::D/D$n.dsk"
    set ::curdisk $n
    L "INSERT disk $n"
}
proc on_bdos {} {
    if {[reg C] != 0x2F || [reg DE] != 0} return
    if {[peek16 [reg SP]] != 0x5BAE} return
    set w [peek 0x5EC0]
    if {$w <= 7} { set want [expr {$w+1}] } elseif {$w == 10} { set want U } else { return }
    if {$want ne $::curdisk} { d $want }
}
debug set_bp 0xF37D {} on_bdos
proc summary {} {
    set f [open "$::T/summary.txt" w]
    puts $f "time=[ts] disk=$::curdisk over=$::over"
    catch { puts $f "E8F5=[format %02X [peek 0xE8F5]] 008F=[format %02X [peek 0x008F]] E8F6=[format %02X [peek 0xE8F6]]" }
    foreach port {FC FD FE FF} {
        set vals {}
        foreach k [lsort [array names ::seen "$port=*"]] { lappend vals "[string range $k 3 end]:$::cnt($k)" }
        puts $f "P$port: $vals"
    }
    close $f
}
proc key {row mask} { keymatrixdown $row $mask ; after time 0.2 "keymatrixup $row $mask" }
proc shot {tag} { screenshot -raw "$::T/s_$tag.png"; summary }
d 1
L "start force=$::FORCE"
