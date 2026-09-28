set ::outdir "/tmp/claude-1000/-home-muhanpong-Projects-Illucity-HD/9addeb9c-ee36-4134-bb7d-dabc7a5d8eac/scratchpad/omsx"
set throttle off
set ::tf [open "$::outdir/emu4_trace.txt" w]
set ::armed 0
proc logbdos {} {
    if {!$::armed} return
    set sp [reg SP]
    puts $::tf [format "t=%.2f C=%02X DE=%04X HL=%04X ret=%04X cur=%d w=%d" [machine_info time] [reg C] [reg DE] [reg HL] [peek16 $sp] [peek 0xCA] [peek 0x5EC0]]
}
debug set_bp 0xF37D {} {logbdos}
proc shot {tag} { screenshot -prefix "emu4_${tag}_" ; flush $::tf }
proc key {row mask} { keymatrixdown $row $mask ; after time 0.25 "keymatrixup $row $mask" }
set power off
hda "/tmp/claude-1000/-home-muhanpong-Projects-Illucity-HD/9addeb9c-ee36-4134-bb7d-dabc7a5d8eac/scratchpad/hd/icity_hd2.dsk"
set power on
after time 30 { type "EMUFILE ICITY.EMU ICITYHD.DSK\r" }
after time 45 { type_via_keybuf "EMUFILE SET ICITY.EMU\r" }
after time 50 { set ::armed 1 }
after time 86 { key 8 0x01 }
after time 92 { key 8 0x40 }
after time 96 { key 8 0x40 }
after time 98 { shot 98 }
after time 100 { key 8 0x01 }
for {set t 110} {$t < 330} {incr t 6} { after time $t {key 8 0x01} }
foreach t {106 120 140 170 200 240 280 320} { after time $t "shot $t" }
after time 330 { shot end; close $::tf; exit }
