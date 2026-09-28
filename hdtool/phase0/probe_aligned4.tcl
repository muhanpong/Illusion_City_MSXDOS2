set throttle off
set power off
hda "/home/muhanpong/Projects/Illucity_HD/hdtool/phase0/img/dos2_aligned.dsk"
set power on
proc poll {n} {
    set f [open "aligned4_trace.txt" a]
    puts $f [format "t=%d PC=%04X SP=%04X A=%02X slotA8=%02X" $n [reg PC] [reg SP] [reg A] [debug read ioports 0xa8]]
    close $f
    if {$n < 30} { after time 1 "poll [expr {$n+1}]" } else { exit }
}
file delete -force aligned4_trace.txt
after time 20 { poll 0 }
