set ::T $SCRATCH/r2
set ::D $SCRATCH/disks
set ::FORCE 0x14
source [file dirname [info script]]/force_e8f5.tcl
after time 28 { key 8 0x40 }
after time 29 { shot menu1 }
after time 30 { key 8 0x01 }
after time 34 { shot menu2 }
after time 36 { key 8 0x40 }
after time 37 { key 8 0x40 }
after time 38 { shot menu2b }
after time 39 { key 8 0x01 }
for {set t 50} {$t <= 400} {incr t 7} { after time $t {key 8 0x01} }
for {set t 45} {$t <= 400} {incr t 15} { after time $t "shot $t" }
after time 401 { summary; exit }
