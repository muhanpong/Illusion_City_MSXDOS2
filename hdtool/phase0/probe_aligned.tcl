set throttle off
set power off
hda "/home/muhanpong/Projects/Illucity_HD/hdtool/phase0/img/dos2_aligned.dsk"
set power on
after time 15 { screenshot -prefix aligned_t15_ }
after time 15 { exit }
