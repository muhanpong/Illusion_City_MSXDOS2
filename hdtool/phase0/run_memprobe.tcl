set throttle off
set power off
hda $::env(IMG)
set power on
after time 40 { type_via_keybuf "MEMPROBE\r" }
after time 48 { screenshot -prefix "memprobe_$::env(TAG)_" ; exit }
