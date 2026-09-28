# Segment-usage trace for Illusion City (original game, floppy).
# - logs every distinct value written to mapper ports FC-FF (first time, PC)
# - auto-swaps disks when the game checks for a disk
# - writes a summary every 10 s (real time) to segtrace_summary.txt
set ::T "/home/muhanpong/Projects/Illucity_HD/hdtool/phase0/segtrace"
set ::log [open "$::T/segtrace_new.log" a]
array set ::seen {}
array set ::cnt {}
set ::curdisk 1
proc ts {} { format %.2f [machine_info time] }
set ::started 0
proc on_map {} {
    set port [expr {$::wp_last_address & 0xFF}]
    set val  $::wp_last_value
    set pc [reg PC]
    # game kernel (FRAY.DOS resident part) lives at E000-E9FF; ignore BIOS/loader probes before it runs
    if {$pc >= 0xE000 && $pc < 0xEA00} { set ::started 1 }
    if {!$::started} return
    set k "[format %02X $port]=[format %02X $val]"
    if {![info exists ::seen($k)]} {
        set ::seen($k) 1
        puts $::log "[ts] NEW P$k PC=[format %04X $pc] disk=$::curdisk"
        flush $::log
    }
    incr ::cnt($k)
}
debug set_watchpoint write_io {0xFC 0xFF} {} on_map
proc d {n} {
    if {$n eq "U"} { diska "$::T/disks/DU.dsk" } else { diska "$::T/disks/D$n.dsk" }
    set ::curdisk $n
    puts $::log "[ts] INSERT disk $n"; flush $::log
}
# auto disk swap: game's disk-check reads sector 0 from file9 routine (return addr 5BAE)
proc on_bdos {} {
    if {[reg C] != 0x2F || [reg DE] != 0} return
    if {[peek16 [reg SP]] != 0x5BAE} return
    set w [peek 0x5EC0]
    if {$w <= 7} { set want [expr {$w+1}] } elseif {$w == 10} { set want U } else { return }
    if {$want ne $::curdisk} { d $want }
}
debug set_bp 0xF37D {} on_bdos
proc summary {} {
    set f [open "$::T/segtrace_summary.txt" w]
    puts $f "time=[ts] disk=$::curdisk"
    catch { puts $f "E8F5(mapper segs)=[format %02X [peek 0xE8F5]] 008F(midi/cache)=[format %02X [peek 0x008F]] E8F6=[format %02X [peek 0xE8F6]]" }
    foreach port {FC FD FE FF} {
        set vals {}
        foreach k [lsort [array names ::seen "$port=*"]] { lappend vals "[string range $k 3 end]:$::cnt($k)" }
        puts $f "P$port: $vals"
    }
    set mx 0
    foreach k [array names ::seen] { scan [string range $k 3 end] %x v; set v [expr {$v & 0x1F}]; if {$v > $mx} {set mx $v} }
    puts $f "max segment (low 5 bits) = $mx  distinct pairs = [array size ::seen]"
    close $f
    after realtime 10 summary
}
after realtime 10 summary
d 1
puts $::log "[ts] trace start"; flush $::log
