# Save persistence test, step 2: fresh boot of the same HD, open the load menu, screenshot T/after.png (slot 2 must now show slot 1's place name).
set throttle off
set firmwareswitch off
hda $::env(HD)
reset
proc key {row mask} { keymatrixdown $row $mask ; after time 0.2 "keymatrixup $row $mask" }
after time 28 { type "ICITY\r" }
after time 52 { key 8 0x01 }
after time 55 { key 8 0x40 }
after time 56 { key 8 0x40 }
after time 57 { key 8 0x40 }
after time 59 { key 8 0x01 }
after time 66 { screenshot -raw $::env(T)/after.png; exit }
