set throttle off
set power off
hda "/home/muhanpong/Projects/Illucity_HD/hdtool/phase0/img/dos2_aligned.dsk"
set power on
after time 30 { screenshot -prefix later_t30_ }
after time 30 { exit }
