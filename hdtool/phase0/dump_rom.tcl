set throttle off
set power off
hda "/home/muhanpong/Projects/Illucity_HD/hdtool/phase0/img/dos2_aligned.dsk"
set power on
after time 20 {
    set blk [debug read_block memory 0x0000 0x4000]
    set f [open "rom_page0.bin" wb]
    puts -nonewline $f $blk
    close $f
    exit
}
