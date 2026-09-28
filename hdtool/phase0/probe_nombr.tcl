set throttle off
set power off
hda "/home/muhanpong/Projects/Illucity_HD/hdtool/phase0/img/dos2_nombr.dsk"
set power on
after time 10 { screenshot -prefix nombr_t10_ }
after time 20 { screenshot -prefix nombr_t20_ }
after time 20 { exit }
