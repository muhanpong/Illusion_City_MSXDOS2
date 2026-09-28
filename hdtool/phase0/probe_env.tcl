set ::outdir [file dirname [info script]]
set ::tag $::env(TAG)
set throttle off
proc probe {} {
    set f [open "$::outdir/env_$::tag.txt" w]
    puts $f "BDOS(0006)=[format %04X [peek16 6]] byte@0006=[format %02X [peek 6]]"
    set fc [debug read ioports 0xfc]; set fd [debug read ioports 0xfd]; set fe [debug read ioports 0xfe]; set ff [debug read ioports 0xff]
    puts $f "mapper ports FC-FF = $fc $fd $fe $ff"
    set found 0
    set orig $ff
    for {set s 0} {$s < 64} {incr s} {
        debug write ioports 0xff $s
        set v [expr {($s*7+13) & 0xff}]
        poke 0xffff $v
        if {[peek 0xffff] == $v} { incr found }
    }
    debug write ioports 0xff $orig
    puts $f "writable mapper segments (page3 poke test 0-63): $found"
    close $f
    screenshot -prefix "env_${::tag}_"
}
set power off
hda "/home/muhanpong/Projects/Illucity_HD/hdtool/phase0/img/dos2_test.dsk"
set power on
after time 20 { probe; exit }
