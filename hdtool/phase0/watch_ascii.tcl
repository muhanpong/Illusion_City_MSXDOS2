set power off
hda "/home/muhanpong/Projects/Illucity_HD/hdtool/phase0/img/dos2_fat12.dsk"
set power on
proc loopshot {} { screenshot -prefix wascii_ ; after realtime 10 loopshot }
after realtime 20 loopshot
