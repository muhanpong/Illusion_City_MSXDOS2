# openMSX test: turn the game's first user-disk save-slot read (2Fh, sector 578h) into a write (30h) and record the DTA;
# afterwards compare ICITY\\SAVE\\DU_0578.DAT (mcopy) with dta.bin: the first H*512 bytes must match, the rest be unchanged.
# env: HD (a copy of the test image), T
set throttle off
set firmwareswitch off
hda $::env(HD)
reset
set ::lg [open "$::env(T)/log.txt" w]
proc L {m} { puts $::lg "[format %.2f [machine_info time]] $m"; flush $::lg }
proc key {row mask} { keymatrixdown $row $mask ; after time 0.2 "keymatrixup $row $mask" }
set ::done 0
proc on_hook {} {
  if {[reg C]==0x2F && [reg DE]==0} { L [format "DISKCHECK 5EC0=%02X" [peek 0x5EC0]] }
  if {[reg C]==0x2F && [reg DE]==0x578 && !$::done} {
    set ::done 1
    set dta [peek16 0xE94A]; set n [expr {[reg H]*512}]
    set f [open "$::env(T)/dta.bin" wb]; puts -nonewline $f [debug read_block memory $dta $n]; close $f
    L [format "INJECT write: DTA=%04X H=%02X" $dta [reg H]]
    reg C 0x30
  }
  if {[reg C]==0x30} { L [format "WRITE DE=%04X H=%02X" [reg DE] [reg H]] }
}
after time 27.5 { debug set_bp 0x0090 {([debug read ioports 0xFC] & 0x1F) != 3} on_hook; debug set_bp 0xC484 {} { L ERR_CTX }; debug set_bp 0xC476 {} { L [format "E_DOS A=%02X" [reg A]] } }
after time 28 { type "ICITY\r" }
after time 52 { key 8 0x01 }
after time 55 { key 8 0x40 }
after time 56 { key 8 0x40 }
after time 57 { key 8 0x40 }
after time 59 { key 8 0x01 }
after time 66 { screenshot -raw $::env(T)/k1.png }
after time 70 { close $::lg; exit }
