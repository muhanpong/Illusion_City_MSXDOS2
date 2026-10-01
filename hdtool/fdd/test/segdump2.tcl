# segdump2.tcl (SONG for run.tcl) - dumps the 512KB Main RAM at $DUMP seconds to $T/ram.bin with the page mapping and
# disk number in $T/map.txt; segan.py then names what each segment holds by matching disk sectors.
array set ::seen {}
proc segn {} { format "FC=%02X FD=%02X FE=%02X FF=%02X" [expr {[debug read ioports 0xFC]&0x1F}] [expr {[debug read ioports 0xFD]&0x1F}] [expr {[debug read ioports 0xFE]&0x1F}] [expr {[debug read ioports 0xFF]&0x1F}] }
debug set_watchpoint write_io {0xFC 0xFF} {[machine_info time] > 20} {
  set k [format "P%02X=%02X" [expr {$::wp_last_address & 0xFF}] [expr {$::wp_last_value & 0x1F}]]
  if {![info exists ::seen($k)]} { set ::seen($k) 1 }
}
after time [expr {$::env(DUMP)-1}] { screenshot -raw $::env(T)/dump.png }
after time $::env(DUMP) {
  set f [open $::env(T)/ram.bin wb]; puts -nonewline $f [debug read_block "Main RAM" 0 524288]; close $f
  set f [open $::env(T)/map.txt w]; puts $f "disk=$::curdisk now [segn]"
  puts $f "scene=[binary encode hex [debug read_block memory 0xC016 3]] disk-var5EC0=[peek 0x5EC0]"; puts $f "E8F3=[format %02X [peek 0xE8F3]] E8F5=[format %02X [peek 0xE8F5]] 008F=[format %02X [peek 0x8F]]"
  puts $f "seen [lsort [array names ::seen]]"; close $f
}
