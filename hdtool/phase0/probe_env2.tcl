set ::outdir [file dirname [info script]]
set throttle off
set power off
hda "/home/muhanpong/Projects/Illucity_HD/hdtool/phase0/img/dos2_test.dsk"
set power on
after time 8 { screenshot -prefix env_t8_ }
after time 15 { screenshot -prefix env_t15_ }
after time 25 { screenshot -prefix env_t25_ }
after time 25 { exit }
