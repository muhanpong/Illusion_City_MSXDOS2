set throttle off
set power off
hda "/home/muhanpong/Projects/Illucity_HD/hdtool/phase0/img/dos2_aligned.dsk"
set power on
proc dump {} {
    set f [open "aligned3_state.txt" w]
    puts $f "PC=[format %04X [reg PC]] SP=[format %04X [reg SP]] A=[format %02X [reg A]]"
    puts $f "slot A8=[format %02X [debug read ioports 0xa8]]"
    for {set i 0} {$i<3} {incr i} {
        after time 0.5
        puts $f "sample $i PC=[format %04X [reg PC]]"
    }
    close $f
}
after time 20 { dump; exit }
