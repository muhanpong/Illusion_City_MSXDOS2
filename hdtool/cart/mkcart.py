#!/usr/bin/env python3
"""mkcart.py - build the Illusion City cartridge ROMs (Yamanooto and ASCII16-X, 8MB each).

usage: mkcart.py <disks> <userdisk.dsk> <font> [outdir]
  <disks>: one 5898240-byte image of disks 1-8 back to back,
           or a folder with the eight 720KB disk images (sorted by name = disk 1..8)
  <font>:  262144 bytes in the Kanji ROM layout (glyph index * 32), e.g. KANJI.rom.
           Always used: patch G1 sends the game's glyph fetch to the font in the cartridge.

ROM layout (both mappers):
  000000h  boot code, page-3 environment, FRAY.DOS (cart.asm, 16KB)
  010000h  disk 1 .. disk 8, user disk (9 x 720KB, sector s of disk d at 10000h + ((d-1)*1440+s)*512)
  664000h  font (256KB, cart.asm FONTSEC)
  6B0000h  save slots (cart.asm SAVESEC): 16 flash sectors of 64KB, slot n of disk 1 = n, of the user disk = 8+n;
           each holds the slot's 2 sectors (0578h+2n) in its first 1KB, the rest 0FFh. Reads and writes of those
           sectors go here; a save erases and reprograms the slot's flash sector.
  7B0000h  0FFh up to 8MB
"""
import os
import shutil
import struct
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
SJASM = os.path.join(HERE, 'sjasmplus')
DISK = 737280
ROMSIZE = 8 << 20
DATA = 0x10000
FONT = 0x664000
SAVE = 0x6B0000
SAVESLOT = 0x10000
SAVEFIRST = 0x578
FONTSIZE = 0x40000
MAPPERS = {1: 'YAMA', 2: 'A16X'}
# G1: disk 1 sector 102 (file7 2AB9h), the game's only Kanji-ROM access (28 bytes) -> JP E947h (cart.asm glyph).
# Some copies have ports 59h/5Bh instead of D9h/DBh; both are replaced the same way.
G1_SEC, G1_OFF = 82 + 0x29B9 // 512, 0x29B9 % 512
G1_ORIG = [bytes.fromhex("7d29296fcb7420040e" + p + "18020e" + q + "ed610ded690c2100d50620edb2c9")
           for p, q in (("d9", "db"), ("59", "5b"))]
G1_NEW = bytes([0xC3, 0x47, 0xE9]) + bytes(25)


def read_disks(path):
    if os.path.isdir(path):
        names = sorted(n for n in os.listdir(path) if n.lower().endswith('.dsk'))
        if len(names) != 8:
            sys.exit(f'{path}: expected 8 .dsk files, found {len(names)}')
        disks = [open(os.path.join(path, n), 'rb').read() for n in names]
    else:
        blob = open(path, 'rb').read()
        if len(blob) != 8 * DISK:
            sys.exit(f'{path}: expected {8 * DISK} bytes, got {len(blob)}')
        disks = [blob[i * DISK:(i + 1) * DISK] for i in range(8)]
    for i, d in enumerate(disks):
        if len(d) != DISK:
            sys.exit(f'disk {i + 1}: expected {DISK} bytes, got {len(d)}')
    return disks


def fat12_file(disk, name):
    """Contents of a root-directory file of a FAT12 disk image."""
    bps, spc, res, nfat, nroot, _, _, spf = struct.unpack_from('<HBHBHHBH', disk, 11)
    root = (res + nfat * spf) * bps
    data = root + nroot * 32
    fat = disk[res * bps:(res + spf) * bps]
    for i in range(nroot):
        e = disk[root + i * 32:root + i * 32 + 32]
        if e[:11] != name:
            continue
        cl, size = struct.unpack_from('<H', e, 26)[0], struct.unpack_from('<I', e, 28)[0]
        out = b''
        while 2 <= cl < 0xFF8 and len(out) < size:
            off = data + (cl - 2) * spc * bps
            out += disk[off:off + spc * bps]
            v = struct.unpack_from('<H', fat, cl * 3 // 2)[0]
            cl = v >> 4 if cl & 1 else v & 0xFFF
        return out[:size]
    sys.exit(f'{name!r} not found on disk 1')


def patch_g1(disk1):
    o = G1_SEC * 512 + G1_OFF
    if disk1[o:o + 28] not in G1_ORIG:
        sys.exit(f'disk 1: unexpected bytes at the glyph routine: {disk1[o:o + 28].hex()}')
    return disk1[:o] + G1_NEW + disk1[o + 28:]


def assemble(mapper, fray, tmp):
    shutil.copy(os.path.join(HERE, 'cart.asm'), tmp)
    with open(os.path.join(tmp, 'fray.dos'), 'wb') as f:
        f.write(fray)
    r = subprocess.run([SJASM, f'-DMAPPER={mapper}', '--nologo', '--msg=war',
                        f'--lst=cart_{MAPPERS[mapper]}.lst', 'cart.asm'],
                       cwd=tmp, capture_output=True, text=True)
    if r.returncode:
        sys.exit(r.stdout + r.stderr)
    boot = open(os.path.join(tmp, 'cart.bin'), 'rb').read()
    assert len(boot) == 0x4000, len(boot)
    return boot


def main():
    if len(sys.argv) < 4:
        sys.exit(__doc__)
    disks = read_disks(sys.argv[1])
    user = open(sys.argv[2], 'rb').read()
    if len(user) != DISK:
        sys.exit(f'{sys.argv[2]}: expected {DISK} bytes')
    font = open(sys.argv[3], 'rb').read()
    if len(font) != FONTSIZE:
        sys.exit(f'{sys.argv[3]}: expected {FONTSIZE} bytes')
    outdir = sys.argv[4] if len(sys.argv) > 4 else '.'
    fray = fat12_file(disks[0], b'FRAY    DOS')
    disks[0] = patch_g1(disks[0])
    data = b''.join(disks) + user
    assert DATA + len(data) <= FONT
    with tempfile.TemporaryDirectory() as tmp:
        for mapper, tag in MAPPERS.items():
            boot = assemble(mapper, fray, tmp)
            rom = bytearray(b'\xff' * ROMSIZE)
            rom[0:len(boot)] = boot
            rom[DATA:DATA + len(data)] = data
            rom[FONT:FONT + FONTSIZE] = font
            for area, disk in enumerate((disks[0], user)):
                for n in range(8):
                    src = (SAVEFIRST + 2 * n) * 512
                    dst = SAVE + (area * 8 + n) * SAVESLOT
                    rom[dst:dst + 1024] = disk[src:src + 1024]
            out = os.path.join(outdir, f'ICITY_{tag}.rom')
            with open(out, 'wb') as f:
                f.write(rom)
            shutil.copy(os.path.join(tmp, f'cart_{tag}.lst'), outdir)
            print(f'{out}: FRAY.DOS {len(fray)} bytes, data {DATA:06X}-{DATA + len(data):06X}')


if __name__ == '__main__':
    main()
