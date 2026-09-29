#!/bin/sh
# build ICITY.COM, the chunk tree and a test HD image
# usage: ./build.sh <disk dir> <out dir> [--midi]   -> <out>/ICITY tree, <out>/chunks.inc, ICITY.COM, and the test HD image <out>.dsk (Nextor sys files)
#   --midi: MIDI build (file13 patches, 19 logical segments); default is the FM-only build (16 segments)
set -e
cd "$(dirname "$0")"
DISKS=$1; OUT=$2; MODE=$3
if [ "$MODE" = "--midi" ]; then NSEG=19; else NSEG=16; fi
python3 mkdos2.py "$DISKS" "$OUT" $MODE
./sjasmplus -DN_SEG=$NSEG -I"$OUT" --lst=icity.lst icity.asm
mkdir -p "$OUT/root" && cp ICITY.COM "$OUT/root/"
python3 mkhd.py "$OUT.dsk" sys "$OUT" "$OUT/root"
grep -E 'e_dos:  push|err_ctx:' icity.lst | awk '{print $2, $NF}'
