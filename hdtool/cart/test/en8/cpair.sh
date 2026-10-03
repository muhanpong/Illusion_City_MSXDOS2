#!/bin/bash
# cpair.sh <data disk 1-4> <slot 1-8> <end s> [A16X|YAMA]: load one save slot of a Japanese "Data Disk" (the user disk built into ROMS/<n>/ICITY_<mapper>.rom)
# on the cartridge, check every read against the disk image (bad=0) and compare the reads with the floppy's (../../../mkdos2/test/en8/cmp_reads.py of pf_<d>_<s>).
# env: WORK, ROMS (dir with out_d1..out_d4 from mkcart), IMGS (dir with all9_1..all9_4.dsk = DUMP_DATA)
T=$(dirname "$(readlink -f "$0")")
d=$1; s=$2; E=$3; mp=${4:-A16X}
D=$WORK/cd_${mp}_${d}_${s}; rm -rf $D; mkdir -p $D
T=$D IMG=$IMGS/all9_$d.dsk MAIN=1 MED=4 SLOT=$s SOUND=0 END=$E DUMPS="" SDL_VIDEODRIVER=dummy SDL_AUDIODRIVER=dummy timeout 900 openmsx -machine Panasonic_FS-A1GT -carta $ROMS/out_d$d/ICITY_$mp.rom $( [ $mp = YAMA ] && echo -romtype Yamanooto ) -script $T/drive.tcl >/dev/null 2>&1
