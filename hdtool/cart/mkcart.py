#!/usr/bin/env python3
"""mkcart.py - build the Illusion City cartridge ROMs (Yamanooto and ASCII16-X): 4MB each, fits any flash of 4MB or
more. The ASCII16-X file carries the "ASCII16X" signature at 0010h (cart.asm), so openMSX and the MiSTer core (mapper
auto) take it as ASCII16-X with flash at 4MB.

usage: mkcart.py <disks> <userdisk.dsk> <font> [outdir]
  <disks>: one 5898240-byte image of disks 1-8 back to back,
           or a folder with the eight 720KB disk images (sorted by name = disk 1..8)
  <font>:  262144 bytes in the Kanji ROM layout (glyph index * 32), e.g. KANJI.rom.
           Always used: patches G1/G2 send the game's glyph fetches (the engine's and the ending intro's) to the font in the cartridge.

Not packed: ARMI.COM and ARMI.DOC (disk 1 sectors 588h-597h, a bonus player; unused by the game) are blanked first.

ROM layout (both mappers):
  000000h  boot code, page-3 environment, FRAY.DOS (cart.asm, 16KB)
  004000h  sector table low words (cart.asm TBLLO), 00A600h high bytes (TBLHI), per sector of disk 1 .. 8, user disk
           (index (d-1)*1440+s): 24-bit value, bits 0-12 offset in its 8KB bank, bit 13 = stored raw (else ZX0),
           bits 14-23 = 8KB bank (split in two arrays so that no entry crosses a 512-byte sector)
  010000h  the sectors, duplicates stored once, ZX0-compressed each (raw when that is not smaller); no sector
           crosses an 8KB bank. Compressor: ZX0 v2.2 by Einar Saukas (zx0/src, BSD-3), built here with cc on first
           use (the web app has a byte-identical port). Results are cached in ~/.cache/icity_zx0.
  310000h  font (256KB, cart.asm FONTSEC)
  350000h  save slots (cart.asm SAVESEC): 96 per disk (disk 1 = 0-95, user disk = 96-191) in 8 groups of 24 slots
           in 9 flash sectors of 64KB (one spare). Slot position p of a group is the 1KB at (p/8)*16KB + (p mod 8)*1KB,
           header 'IC', group, 16-bit generation at +C000h; per group the valid, newer header wins, the sector
           without one is the spare. The disks' own 8 slots each (sectors 0578h+2n) start in groups 0 and 4.
  3E0000h  0FFh up to 4MB
"""
import hashlib
import os
import shutil
import struct
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
SJASM = os.path.join(HERE, 'sjasmplus')
DISK = 737280
ROMSIZE = 4 << 20
# file size per mapper (both 4MB: the ASCII16-X signature replaces the 8MB padding the MiSTer core needed before)
FILESIZE = {'YAMA': 4 << 20, 'A16X': 4 << 20}
TBLLO = 0x4000          # cart.asm TBLLO
TBLHI = 0xA600          # cart.asm TBLHI
DATA = 0x10000
DATAEND = 0x310000
FONT = 0x310000         # cart.asm FONTSEC
SAVE = 0x350000         # cart.asm SAVESEC
SAVEFIRST = 0x578
SLOTS = 96              # per disk (cart.asm PAGES * 8)
GROUP = 24              # slots per group (one 64KB flash sector)
NSAVE = 9               # flash sectors for the 8 groups + 1 spare


def save_layout(disk1, user):
    """{ROM offset: bytes} of the save area: group g in flash sector g (generation 1), sector 8 spare (erased)."""
    out = {}
    for g in range(2 * SLOTS // GROUP):
        out[SAVE + g * 0x10000 + 0xC000] = b'IC' + bytes([g]) + b'\x01\x00'
    for area, disk in enumerate((disk1, user)):
        for n in range(8):
            slot = area * SLOTS + n
            g, p = divmod(slot, GROUP)
            src = (SAVEFIRST + 2 * n) * 512
            out[SAVE + g * 0x10000 + (p >> 3) * 0x4000 + (p & 7) * 0x400] = disk[src:src + 1024]
    return out


def zx0tool():
    """The ZX0 reference compressor, built from zx0/src into ~/.cache/icity_zx0 (or ZX0=path)."""
    if os.environ.get('ZX0'):
        return os.environ['ZX0']
    cache = os.path.join(os.path.expanduser('~'), '.cache', 'icity_zx0')
    os.makedirs(cache, exist_ok=True)
    exe = os.path.join(cache, 'zx0')
    if not os.path.exists(exe):
        src = os.path.join(HERE, 'zx0', 'src')
        r = subprocess.run([os.environ.get('CC', 'cc'), '-O2', '-o', exe] +
                           [os.path.join(src, f) for f in ('zx0.c', 'optimize.c', 'compress.c', 'memory.c')],
                           capture_output=True, text=True)
        if r.returncode:
            sys.exit('building zx0 failed (needs a C compiler, or ZX0=/path/to/zx0):\n' + r.stderr)
    return exe


def zx0(block, tool, cache):
    """ZX0 of one 512-byte sector (cached by content)."""
    h = hashlib.sha1(block).hexdigest()
    path = os.path.join(cache, h)
    if not os.path.exists(path):
        with tempfile.TemporaryDirectory(dir=cache) as t:     # same filesystem as the cache (os.replace)
            src, dst = os.path.join(t, 'in'), os.path.join(t, 'out')
            open(src, 'wb').write(block)
            subprocess.run([tool, '-f', src, dst], check=True, capture_output=True)
            os.replace(dst, path)
    return open(path, 'rb').read()


def pack(data):
    """data = 9 disks back to back -> (table bytes, packed bytes placed at DATA)."""
    tool = zx0tool()
    cache = os.path.join(os.path.expanduser('~'), '.cache', 'icity_zx0', 'v22')
    os.makedirs(cache, exist_ok=True)
    blob = bytearray()
    where = {}
    lo = bytearray()
    hi = bytearray()
    for i in range(len(data) // 512):
        sec = data[i * 512:(i + 1) * 512]
        if sec not in where:
            c = zx0(sec, tool, cache)
            raw = len(c) >= 512
            item = sec if raw else c
            if (len(blob) & 0x1FFF) + len(item) > 0x2000:       # never across an 8KB bank
                blob += b'\xff' * (0x2000 - (len(blob) & 0x1FFF))
            where[sec] = ((DATA + len(blob)) >> 13, len(blob) & 0x1FFF, raw)
            blob += item
        bank, off, raw = where[sec]
        v = off | (0x2000 if raw else 0) | (bank << 14)
        lo += bytes([v & 0xFF, (v >> 8) & 0xFF])
        hi.append(v >> 16)
    if DATA + len(blob) > DATAEND:
        sys.exit(f'packed data too big: {len(blob)} bytes')
    assert TBLLO + len(lo) <= TBLHI and TBLHI + len(hi) <= DATA
    return bytes(lo), bytes(hi), bytes(blob), len(where)
FONTSIZE = 0x40000
MAPPERS = {1: 'YAMA', 2: 'A16X'}
# G1: disk 1 sector 102 (file7 2AB9h), the game's only Kanji-ROM access (28 bytes) -> JP E947h (cart.asm glyph).
# Some copies have ports 59h/5Bh instead of D9h/DBh; both are replaced the same way.
G1_SEC, G1_OFF = 82 + 0x29B9 // 512, 0x29B9 % 512
G1_ORIG = [bytes.fromhex("7d29296fcb7420040e" + p + "18020e" + q + "ed610ded690c2100d50620edb2c9")
           for p, q in (("d9", "db"), ("59", "5b"))]
G1_NEW = bytes([0xC3, 0x47, 0xE9]) + bytes(25)
# G2: disk 1 file 14 (the ending intro, loaded at 8000h) has its own copy of that routine at ADFEh (same 28 bytes; the glyph goes to
# 86BCh and it returns HL=86DCh).  -> CALL E947h (the glyph routine above, glyph in D500h), then copy the 32 bytes:
# LD HL,D500h / LD DE,86BCh / LD BC,0020h / LDIR / EX DE,HL / RET
G2_SEC, G2_OFF = 238 + 0x2DFE // 512, 0x2DFE % 512
G2_ORIG = [bytes.fromhex("7d29296fcb7420040e" + p + "18020e" + q + "ed610ded690c21bc860620edb2c9")
           for p, q in (("d9", "db"), ("59", "5b"))]
G2_NEW = bytes.fromhex("cd47e9" "2100d5" "11bc86" "012000" "edb0" "eb" "c9").ljust(28, b'\0')


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


# Save-list paging (cart.asm uiimg), in file9 (disk 1 sectors 156.., loaded at 4000h). addr: (original, new)
FILE9_SEC, FILE9_BASE = 156, 0x4000


def ui_patches(sym):
    w = lambda a: bytes([a & 0xFF, a >> 8])
    return {
        0x590A: (bytes.fromhex('210000'), b'\x21' + w(sym['cbk'])),        # P1 menu callback
        0x5957: (bytes.fromhex('326ad5'), b'\xcd' + w(sym['fixno'])),      # P2 number shown
        0x5910: (bytes.fromhex('32c55e'), b'\xcd' + w(sym['fixsel'])),     # P3 slot selected
        0x58E3: (bytes.fromhex('cd4459'), b'\xcd' + w(sym['newlist'])),    # P4 list opened
        0x5A66: (bytes.fromhex('2178051919'), b'\xcd' + w(sym['secof']) + bytes(2)),   # P5 read sector
        0x5A8F: (bytes.fromhex('2178051919'), b'\xcd' + w(sym['secof']) + bytes(2)),   # P6 write sector
    }


def patch_ui(disk1, sym):
    d = bytearray(disk1)
    for addr, (orig, new) in ui_patches(sym).items():
        o = FILE9_SEC * 512 + addr - FILE9_BASE
        if d[o:o + len(orig)] != orig:
            sys.exit(f'disk 1: unexpected bytes at file9 {addr:04X}: {d[o:o + len(orig)].hex()}')
        d[o:o + len(new)] = new
    return bytes(d)


def patch_g1(disk1):
    o = G1_SEC * 512 + G1_OFF
    if disk1[o:o + 28] not in G1_ORIG:
        sys.exit(f'disk 1: unexpected bytes at the glyph routine: {disk1[o:o + 28].hex()}')
    return disk1[:o] + G1_NEW + disk1[o + 28:]


def patch_g2(disk1):
    o = G2_SEC * 512 + G2_OFF
    if disk1[o:o + 28] not in G2_ORIG:
        sys.exit(f'disk 1: unexpected bytes at the ending text glyph routine (file 14): {disk1[o:o + 28].hex()}')
    return disk1[:o] + G2_NEW + disk1[o + 28:]


# ARMI.COM / ARMI.DOC (the author's bonus RCP player and its document, disk 1 sectors 588h-597h): the game never reads them and
# the cartridge has no file system to reach them, so they are not packed: the sectors become the disk's own free-space fill.
ARMI_FIRST, ARMI_LAST = 0x588, 0x597
ARMI_HEADS = {0x588: bytes.fromhex('c30301cdd102'), 0x58E: b'Please read following;'}


def blank_armi(disk1):
    for s, head in ARMI_HEADS.items():
        if disk1[s * 512:s * 512 + len(head)] != head:
            sys.exit(f'disk 1: sector {s:03X}h does not start like ARMI (this is not the supported release)')
    fill = disk1[0x598 * 512:0x599 * 512]
    if fill.count(fill[0]) != 512:
        sys.exit('disk 1: sector 598h is not free space (this is not the supported release)')
    return disk1[:ARMI_FIRST * 512] + fill * (ARMI_LAST - ARMI_FIRST + 1) + disk1[(ARMI_LAST + 1) * 512:]


def assemble(mapper, fray, tmp):
    shutil.copy(os.path.join(HERE, 'cart.asm'), tmp)
    os.makedirs(os.path.join(tmp, 'zx0'), exist_ok=True)
    shutil.copy(os.path.join(HERE, 'zx0', 'dzx0_standard.asm'), os.path.join(tmp, 'zx0'))
    with open(os.path.join(tmp, 'fray.dos'), 'wb') as f:
        f.write(fray)
    r = subprocess.run([SJASM, f'-DMAPPER={mapper}', '--nologo', '--msg=war',
                        f'--lst=cart_{MAPPERS[mapper]}.lst', '--sym=cart.sym', 'cart.asm'],
                       cwd=tmp, capture_output=True, text=True)
    if r.returncode:
        sys.exit(r.stdout + r.stderr)
    boot = open(os.path.join(tmp, 'cart.bin'), 'rb').read()
    assert len(boot) == 0x4000, len(boot)
    sym = {}
    for line in open(os.path.join(tmp, 'cart.sym')):
        m = line.split()
        if len(m) == 3 and m[1] == 'EQU' and m[0].endswith(':'):
            sym[m[0][:-1]] = int(m[2], 16)
    return boot, sym


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
    disks[0] = blank_armi(patch_g2(patch_g1(disks[0])))
    with tempfile.TemporaryDirectory() as tmp:
        syms = {}
        boots = {}
        for mapper in MAPPERS:
            boots[mapper], syms[mapper] = assemble(mapper, fray, tmp)
        ui = [ui_patches(syms[m]) for m in MAPPERS]
        assert all(u == ui[0] for u in ui), 'page-3 UI addresses differ between mappers'
        disks[0] = patch_ui(disks[0], syms[1])
        data = b''.join(disks) + user
        if os.environ.get('DUMP_DATA'):                  # tests: the disks as the ROM serves them (patched)
            open(os.environ['DUMP_DATA'], 'wb').write(data)
        tlo, thi, blob, nuniq = pack(data)
        for mapper, tag in MAPPERS.items():
            boot = boots[mapper]
            rom = bytearray(b'\xff' * FILESIZE[tag])
            rom[0:len(boot)] = boot
            rom[TBLLO:TBLLO + len(tlo)] = tlo
            rom[TBLHI:TBLHI + len(thi)] = thi
            rom[DATA:DATA + len(blob)] = blob
            rom[FONT:FONT + FONTSIZE] = font
            for off, b in save_layout(disks[0], user).items():
                rom[off:off + len(b)] = b
            out = os.path.join(outdir, f'ICITY_{tag}.rom')
            with open(out, 'wb') as f:
                f.write(rom)
            shutil.copy(os.path.join(tmp, f'cart_{tag}.lst'), outdir)
            print(f'{out}: FRAY.DOS {len(fray)} bytes, {len(data) // 512} sectors ({nuniq} distinct) packed '
                  f'{DATA:06X}-{DATA + len(blob):06X}')


if __name__ == '__main__':
    main()
