# gl.tcl (SONG for run.tcl) - logs every distinct glyph number the original game asks its reader (file 7 2AB9h) for.
set ::gl [open "$::T/glyph.log" w]
array set ::gs {}
debug set_bp 0x2AB9 {[peek 0x2AB9] == 0x7D && [peek 0x2ABA] == 0x29} { set k [format %04X [reg HL]]; if {![info exists ::gs($k)]} { set ::gs($k) 1; puts $::gl "$k [format %.1f [machine_info time]] disk=$::curdisk"; flush $::gl } }
