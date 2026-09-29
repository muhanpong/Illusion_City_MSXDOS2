# Save persistence test, step 1: on the first user-disk slot read (2Fh, sector 578h) put the real slot-1 data (T/slot1.bin,
# first 1024 bytes of ICITY\SAVE\DU_0578.DAT) in the DTA and turn the call into a WRITE to sector 057Ah (slot 2).
# env: HD (copy of the test image, ext depends on image), T (dir containing slot1.bin). Step 2: save_persist_reload.tcl on the same HD.
set throttle off
set firmwareswitch off
hda $::env(HD)
reset
set ::lg [open "$::env(T)/log1.txt" w]
proc L {m} { puts $::lg "[format %.2f [machine_info time]] $m"; flush $::lg }
proc key {row mask} { keymatrixdown $row $mask ; after time 0.2 "keymatrixup $row $mask" }
set ::done 0
proc on_hook {} {
  if {[reg C]==0x2F && [reg DE]==0x578 && !$::done} {
    set ::done 1
    set dta [peek16 0xE94A]
    set f [open "$::env(T)/slot1.bin" rb]; set d [read $f]; close $f
    for {set i 0} {$i < 1024} {incr i} { poke [expr {$dta+$i}] [scan [string index $d $i] %c] }
    L [format "INJECT: slot1 data -> DTA %04X, write to sector 057A (was 2Fh DE=0578)" $dta]
    reg C 0x30
    reg DE 0x057A
  }
}
after time 27.5 { debug set_bp 0x0090 {([debug read ioports 0xFC] & 0x1F) != 3} on_hook; debug set_bp 0xC484 {} { L ERR_CTX }; debug set_bp 0xC476 {} { L [format "E_DOS A=%02X" [reg A]] } }
after time 28 { type "ICITY\r" }
after time 52 { key 8 0x01 }
after time 55 { key 8 0x40 }
after time 56 { key 8 0x40 }
after time 57 { key 8 0x40 }
after time 59 { key 8 0x01 }
after time 66 { screenshot -raw $::env(T)/before.png }
after time 68 { close $::lg; exit }
