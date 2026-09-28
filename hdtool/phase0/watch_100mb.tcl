set power off
hda "/home/muhanpong/Projects/Illucity_HD/hdtool/phase0/img/dos2_100mb.dsk"
set power on
proc loopshot {} { screenshot -prefix watch_ ; after time 5 loopshot }
after time 5 loopshot
