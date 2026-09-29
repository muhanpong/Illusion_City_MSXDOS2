#!/bin/sh
# build ICITY.COM, the chunk tree and a test HD image
# usage: ./build.sh <disk dir> <out dir> [-DFORCE_FM=1]   -> <out>/ICITY tree, <out>/chunks.inc, ICITY.COM, and the test HD image <out>.dsk
# FONT=/path/FONT.BIN ./build.sh ...   ships the font and activates patch G1 (no Kanji ROM needed)
# SYSDIR=sys_ascii ./build.sh ...     test image for the ASCII DOS2 kernel (MSXDOS2.SYS + COMMAND2.COM, run with -ext ide);
#                                       default sys = Nextor (NEXTOR.SYS, run with -ext SunriseIDE_Nextor)
# One build serves both sound modes: the launcher picks MIDI+FM (sound menu, 19 segments) when >= 19 mapper segments are
# free and FM only (16 segments) otherwise.  -DFORCE_FM=1 forces the FM-only mode for testing.
set -e
cd "$(dirname "$0")"
DISKS=$1; OUT=$2; shift 2
python3 mkdos2.py "$DISKS" "$OUT" ${FONT:+--font "$FONT"}
./sjasmplus "$@" -I"$OUT" --lst=icity.lst icity.asm
mkdir -p "$OUT/root" && cp ICITY.COM "$OUT/root/"
python3 mkhd.py "$OUT.dsk" "${SYSDIR:-sys}" "$OUT" "$OUT/root"
grep -E 'e_dos:  push|err_ctx:' icity.lst | awk '{print $2, $NF}'
