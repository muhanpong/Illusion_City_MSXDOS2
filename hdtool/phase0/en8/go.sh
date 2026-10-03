#!/bin/bash
# usage: go.sh name MAIN END "KEYS" "DUMPS"
S=/tmp/claude-1000/-home-sysop-data-Illucity-HD-en/e581fbf4-f888-4479-9671-5fbd81b032f1/scratchpad; cd $S; mkdir -p $1
S=$S T=$S/$1 D=$S/en SONG=$S/song13.tcl SOUND=0 MAIN=$2 END=$3 BOT0=1100 BOT1=1229 KEYS="$4" DUMPS="$5" WSTART=99999 SDL_VIDEODRIVER=dummy SDL_AUDIODRIVER=dummy timeout 600 openmsx -machine Panasonic_FS-A1GT -script run_en.tcl >/dev/null 2>&1
for f in $1/v*.bin; do python3 vr.py ${f%.bin} ${f%.bin}.png; done
