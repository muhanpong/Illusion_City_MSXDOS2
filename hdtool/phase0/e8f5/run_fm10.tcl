set ::T $SCRATCH/r5
set ::D $SCRATCH/disks
set ::FORCE 0x10
source [file dirname [info script]]/force_e8f5.tcl
after time 30 { key 8 0x40 }
after time 31 { key 8 0x40 }
after time 32 { shot menu }
after time 33 { key 8 0x01 }
for {set t 45} {$t <= 330} {incr t 7} { after time $t {key 8 0x01} }
for {set t 45} {$t <= 330} {incr t 30} { after time $t "shot $t" }
after time 331 { summary; exit }
