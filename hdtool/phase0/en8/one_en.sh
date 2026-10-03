#!/bin/bash
# one_en.sh <datadisk 1-4> <slot> <end> "<dump times>"
S=/tmp/claude-1000/-home-sysop-data-Illucity-HD-en/e581fbf4-f888-4479-9671-5fbd81b032f1/scratchpad; cd $S
d=$1; s=$2; R=$S/q_${d}_${s}; rm -rf $R; mkdir -p $R/disks
for i in 1 2 3 4 5 6 7 8; do cp $S/en/D$i.dsk $R/disks/D$i.dsk 2>/dev/null || cp -L $S/en/D$i.dsk $R/disks/D$i.dsk; done
J=$(ls /home/sysop/illusion_city/x/ja/*.dsk | sort | sed -n "$((8+d))p"); cp "$J" $R/disks/DU.dsk
S=$S T=$R D=$R/disks SONG=$S/song14.tcl DUMPS="$4" SOUND=0 MAIN=1 MED=4 SLOT=$s END=$3 WSTART=99999 SDL_VIDEODRIVER=dummy SDL_AUDIODRIVER=dummy timeout 900 openmsx -machine Panasonic_FS-A1GT -script run_en.tcl >/dev/null 2>&1
