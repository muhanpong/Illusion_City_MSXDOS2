#!/bin/sh
# build ICITY.COM and (optionally) the chunk tree + test HD image
# usage: ./build.sh <disk dir> <out dir>     -> <out>/ICITY tree, <out>/chunks.inc, ICITY.COM, <out>/hd_nextor.dsk
set -e
cd "$(dirname "$0")"
DISKS=$1; OUT=$2
python3 mkdos2.py "$DISKS" "$OUT"
./sjasmplus -I"$OUT" --lst=icity.lst icity.asm
mkdir -p "$OUT/root" && cp ICITY.COM "$OUT/root/"
python3 mkhd.py "$OUT/hd_nextor.dsk" sys "$OUT" "$OUT/root"
grep -E 'e_dos:  push|err_ctx:' icity.lst | awk '{print $2, $NF}'
