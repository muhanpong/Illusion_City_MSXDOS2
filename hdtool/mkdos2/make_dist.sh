#!/bin/sh
# make_dist.sh <src> <font> <out dir> [--fm-only]
#   <src>  directory holding I-City(k)(1-8).dsk .. (8-8).dsk and the user disk (userdisk.DSK / I-City(k)(U).dsk),
#          or the illucity_K.zip with the eight disks plus USERDISK=<file> in the environment
#   <font> FONT.BIN (KANJI.rom layout, 262144 bytes)
#   <out>  receives ICITY.COM, ICITY\..., DIST README, SHA1SUMS.txt - copy its contents to the SD card root.
# env: MERGE=N merges chunks shorter than N sectors (fewer files), e.g. MERGE=16.
set -e
SRC=$(realpath "$1"); FONT=$(realpath "$2"); OUT=$(realpath -m "$3"); shift 3
[ -n "$USERDISK" ] && USERDISK=$(realpath "$USERDISK")
cd "$(dirname "$0")"
[ -f "$FONT" ] || { echo "font not found: $FONT" >&2; exit 1; }
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
if [ -f "$SRC" ]; then
  unzip -q -o "$SRC" -d "$TMP/disks"
  [ -n "$USERDISK" ] && cp "$USERDISK" "$TMP/disks/"
  SRCDIR=$TMP/disks
else
  SRCDIR=$SRC
fi
rm -rf "$OUT"; mkdir -p "$OUT"
python3 mkdos2.py "$SRCDIR" "$TMP/tree" --font "$FONT" ${MERGE:+--merge "$MERGE"} "$@"
./sjasmplus -I"$TMP/tree" --lst="$TMP/icity.lst" icity.asm >/dev/null
cp ICITY.COM "$OUT/"
cp -r "$TMP/tree/ICITY" "$OUT/"
cp DIST_README.txt "$OUT/README.TXT"
( cd "$OUT" && find . -type f ! -name SHA1SUMS.txt | sort | xargs sha1sum > SHA1SUMS.txt )
echo "dist: $(find "$OUT" -type f | wc -l) files, $(du -sh "$OUT" | cut -f1)"
