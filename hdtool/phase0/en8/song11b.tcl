proc dumpv {tag} {
  set f [open "$::T/v$tag.bin" wb]; fconfigure $f -translation binary; puts -nonewline $f [debug read_block VRAM 0 131072]; close $f
  set f [open "$::T/v$tag.txt" w]
  set r {}; for {set i 0} {$i < 28} {incr i} { lappend r [vdpreg $i] }
  set c {}; for {set i 0} {$i < 16} {incr i} { lappend c [getcolor $i] }
  puts $f "regs $r"; puts $f "colors $c"; close $f }
