#!/usr/bin/env python3
"""Build ICITYHD.DSK: 8 game disks + 1 user disk merged into one 6.5MB FAT12 image
whose FRAY.DOS carries a BDOS hook that switches disks automatically."""
import sys, struct, os
SRC = sys.argv[1] if len(sys.argv) > 1 else "/home/muhanpong/Projects/Illucity_HD"
OUT = sys.argv[2] if len(sys.argv) > 2 else "ICITYHD.DSK"
HOOK = os.path.join(os.path.dirname(os.path.abspath(__file__)), "hookpatch.bin")
DISK = 737280; SEC = 512
regions = []
for i in range(1, 9):
    d = open(os.path.join(SRC, f"I-City(k)({i}-8).dsk"), "rb").read()
    assert len(d) == DISK, i
    assert d[3:10] == f"IPROJ0{i}".encode(), d[3:10]
    regions.append(bytearray(d))
upath = sys.argv[3] if len(sys.argv) > 3 else os.path.join(SRC, "I-City(k)(U).dsk")   # user (save) disk
user = bytearray(open(upath, "rb").read()) if os.path.exists(upath) else bytearray(DISK)
assert len(user) == DISK
# The game treats any disk whose label (+3) is not IPROJ0n as the user disk.
# Keep a given user disk byte-for-byte; only give a blank/labelless one a boot sector.
if not any(user[0:SEC]) or user[3:8] == b"IPROJ":
    user[0:SEC] = regions[0][0:SEC]
    user[3:11] = b"USERDISK"
print("user disk region:", upath if os.path.exists(upath) else "blank", "label", bytes(user[3:11]))
regions.append(user)
d1 = regions[0]
total = 9 * DISK // SEC                   # 12960 sectors
# --- BPB of region 1 describes the whole image as one FAT12 volume (DOS1 compatible: 3 sectors/FAT)
d1[0x0D] = 16                              # sectors per cluster -> 809 clusters (FAT12)
struct.pack_into("<H", d1, 0x13, total)    # total sectors
d1[0x15] = 0xF8                            # media: fixed disk
struct.pack_into("<H", d1, 0x18, 32)       # sectors/track (cosmetic)
struct.pack_into("<H", d1, 0x1A, 8)        # heads (cosmetic)
for fat in (1, 4):                         # FAT ID byte in both FAT copies
    d1[fat*SEC] = 0xF8
# --- patch FRAY.DOS (sectors 14..): JP to installer at 0xDA2, append hook patch
fray = 14 * SEC
assert d1[fray:fray+3] == b"\x21\x5b\x04"
hook = open(HOOK, "rb").read()
d1[fray:fray+3] = b"\xC3\xA2\x0D"
orig_len = 0x0CA2
d1[fray+orig_len:fray+orig_len+len(hook)] = hook
new_len = orig_len + len(hook)
assert fray + new_len <= 22 * SEC          # must not run into file #0 at sector 0x16
# directory entry 0 (FRAY.DOS) size
assert d1[0xE00:0xE0B] == b"FRAY    DOS"
struct.pack_into("<I", d1, 0xE1C, new_len)
img = b"".join(regions)
open(OUT, "wb").write(img)
print(f"wrote {OUT}: {len(img)} bytes, {total} sectors, FRAY.DOS {orig_len}->{new_len} bytes, hook {len(hook)} bytes")
