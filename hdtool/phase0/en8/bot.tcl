# field bot: dialogue menu (3 items) autopilot. targets in ::targets, then space-mash
proc px {x y} { set v [vpeek [expr {$y*128 + $x/2}]]; if {$x % 2 == 0} { return [expr {$v >> 4}] } else { return [expr {$v & 15}] } }
set ::step 0; set ::busy 0; set ::lastp 0
proc bot {} {
  if {[machine_info time] > $::env(BOT1)} return
  set t [machine_info time]
  if {$t > $::busy} {
    if {[px 200 4] == 12 && [px 200 5] == 11} {
      set cur [expr {[px 150 14] == 13 ? 0 : ([px 150 26] == 13 ? 1 : ([px 150 38] == 13 ? 2 : -1))}]
      if {$::step < [llength $::targets]} {
        set tg [lindex $::targets $::step]
        if {$cur < 0} {} elseif {$cur < $tg} { key 8 0x40; set ::busy [expr {$t+0.7}] } elseif {$cur > $tg} { key 8 0x20; set ::busy [expr {$t+0.7}] } else { key 8 0x01; incr ::step; set ::busy [expr {$t+2.5}]; set ::lastp $t; L "bot: picked $tg step=$::step" }
      }
    } elseif {$t - $::lastp > 2.5} { key 8 0x01; set ::lastp $t; set ::busy [expr {$t+0.5}] }
  }
  after time 0.4 bot
}
set ::targets {1 2 0 2 1 0 2 1 0 2 1 0 2 1 0 2 1 0 2 1 0 2 1 0}
after time $::env(BOT0) bot
