#!/bin/bash
# pair.sh <data disk 1-4> <slot 1-8> <end s>: the original floppy game and the DOS2 build load the same save slot (user disk = a Japanese
# "Data Disk" image); then cmp_reads.py compares every sector read (they must be identical).
# env: WORK (scratch dir), EN (dir with D1.dsk..D8.dsk of the English release), DUDIR (dir with DU1.dsk..DU4.dsk = the 4 data disks),
#      HDS (dir with eo_1.dsk..eo_4.dsk: DOS2 images built with DU = data disk n), SOUND (0 FM / 1 MIDI)
set -e
T=$(dirname "$(readlink -f "$0")")
d=$1; s=$2; E=$3
F=$WORK/pf_${d}_${s}; D=$WORK/pd_${d}_${s}; rm -rf $F $D; mkdir -p $F/disks $D
for i in 1 2 3 4 5 6 7 8; do cp $EN/D$i.dsk $F/disks/D$i.dsk; done
cp $DUDIR/DU$d.dsk $F/disks/DU.dsk
(T=$F D=$F/disks SONG=$T/floppy_reads.tcl SOUND=${SOUND:-0} MAIN=1 MED=4 SLOT=$s END=$E WSTART=99999 SDL_VIDEODRIVER=dummy SDL_AUDIODRIVER=dummy timeout 600 openmsx -machine Panasonic_FS-A1GT -script $T/floppy_run.tcl >/dev/null 2>&1) &
(HD=$HDS/eo_$d.dsk T=$D MAIN=1 MED=4 SLOT=$s SOUND=${SOUND:-0} END=$((E+30)) DUMPS="" SDL_VIDEODRIVER=dummy SDL_AUDIODRIVER=dummy timeout 600 openmsx -machine Panasonic_FS-A1GT -ext SunriseIDE_Nextor -script $T/drive.tcl >/dev/null 2>&1) &
wait
python3 $T/cmp_reads.py $F/reads.log $D/reads.log
