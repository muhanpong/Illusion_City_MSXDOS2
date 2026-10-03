#!/bin/sh
# test_cli.sh - build the reference outputs with this branch's Python tools and compare core.js against them (English 8-disc
# and Japanese releases; the Korean release has test_node.js, test_cart.js, test_fdd.js).
# usage: test_cli.sh <work dir> <English disk dir> <Japanese disk dir> <user disk> <Japanese Kanji ROM file>
#   disk dirs: the eight .dsk of the release (sorted by name = disk 1..8); work dir: scratch space (several hundred MB)
# runs: English (no font), Japanese without a font, Japanese with the Kanji ROM file as the font; each: mkdos2.py + launcher
# (build.sh steps), mkcart.py --pad8, then test_en8.js / test_ja.js.
set -e
W=$1; EN=$2; JA=$3; USER=$4; KROM=$5
H=$(cd "$(dirname "$0")/.." && pwd)
mkdir -p "$W"
prep() {   # prep <name> <disk dir>: the eight disks as D1..D8 + DU
  mkdir -p "$W/$1/in" "$W/$1/g"; i=1
  for f in "$2"/*.dsk "$2"/*.DSK; do [ -f "$f" ] || continue; [ $i -le 8 ] && cp "$f" "$W/$1/g/D$i.dsk"; i=$((i+1)); done
  cp "$W/$1/g/"*.dsk "$W/$1/in/"; cp "$USER" "$W/$1/in/DU.dsk"     # in/: disks 1-8 + DU for mkdos2.py, g/: the eight for mkcart.py
}
dos2() {   # dos2 <name> [font]: chunk tree + ICITY.COM as build.sh makes them
  (cd "$H/mkdos2" && python3 mkdos2.py "$W/$1/in" "$W/$1/tree" ${2:+--font "$2"} >/dev/null &&
   if grep -q '"release": "en8"' "$W/$1/tree/manifest.json"; then E=-DEN8; else E=; fi &&
   ./sjasmplus $E -I"$W/$1/tree" --lst="$W/$1/icity.lst" icity.asm >/dev/null 2>&1 && cp ICITY.COM "$W/$1/ICITY.COM")
}
cart() { mkdir -p "$W/$1/rom"; python3 "$H/cart/mkcart.py" --pad8 "$W/$1/g" "$W/$1/in/DU.dsk" "$2" "$W/$1/rom" >/dev/null; }
prep en "$EN"; dos2 en; cart en -
prep ja "$JA"; dos2 ja; cart ja -
prep jaf "$JA"; dos2 jaf "$KROM"; cart jaf "$KROM"
# several user disks (pages 1..N): the given user disk + the Japanese "Data Disk"s found next to the Japanese game disks (DATA*)
prep jau "$JA"; mkdir -p "$W/jau/u"; cp "$USER" "$W/jau/u/u01.dsk"; k=2
for f in "$JA"/../*Data*Disk*.dsk "$JA"/DATA*.dsk; do [ -f "$f" ] && cp "$f" "$W/jau/u/u0$k.dsk" && k=$((k+1)); done
MORE=$(for f in "$W/jau/u"/u0[2-9].dsk; do [ -f "$f" ] && printf -- '--user %s ' "$f"; done)
(cd "$H/mkdos2" && python3 mkdos2.py "$W/jau/in" "$W/jau/tree" $MORE >/dev/null && ./sjasmplus -I"$W/jau/tree" --lst="$W/jau/icity.lst" icity.asm >/dev/null 2>&1 && cp ICITY.COM "$W/jau/ICITY.COM")
mkdir -p "$W/jau/rom"; python3 "$H/cart/mkcart.py" --pad8 $MORE "$W/jau/g" "$W/jau/u/u01.dsk" - "$W/jau/rom" >/dev/null
rc=0
echo "== English 8-disc"; node "$H/webapp/test_en8.js" "$W/en/g" "$W/en/in/DU.dsk" "$W/en/tree" "$W/en/ICITY.COM" "$W/en/rom" | grep -v '^ ' || rc=1
echo "== Japanese, no font"; node "$H/webapp/test_ja.js" "$W/ja/g" "$W/ja/in/DU.dsk" - "$W/ja/tree" "$W/ja/ICITY.COM" "$W/ja/rom" | grep -v '^ ' || rc=1
echo "== Japanese, Kanji ROM file as font"; node "$H/webapp/test_ja.js" "$W/jaf/g" "$W/jaf/in/DU.dsk" "$KROM" "$W/jaf/tree" "$W/jaf/ICITY.COM" "$W/jaf/rom" | grep -v '^ ' || rc=1
echo "== Japanese, $(ls "$W/jau/u" | wc -l) user disks"; node "$H/webapp/test_ja.js" "$W/jau/g" "$(ls "$W/jau/u"/*.dsk | paste -sd,)" - "$W/jau/tree" "$W/jau/ICITY.COM" "$W/jau/rom" | grep -v '^ ' || rc=1
exit $rc
