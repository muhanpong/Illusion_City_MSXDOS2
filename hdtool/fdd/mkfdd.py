#!/usr/bin/env python3
"""mkfdd.py - Illusion City floppy version that needs no Korean Kanji ROM: patches disk 1 so that the game's glyphs come
from a font stored on the disk itself. Disks 2-8 and the user disk are unchanged.

usage: mkfdd.py <disk dir> <KANJI.rom> <out dir>
  <disk dir>: the eight 720KB images, named D1.dsk..D8.dsk or I-City(k)(1-8).dsk..(8-8).dsk
  <KANJI.rom>: 262144 bytes, the Korean Kanji ROM layout (glyph number * 32); only the glyphs the game prints are used
Writes <out dir>/D1.dsk .. D8.dsk.

What changes on disk 1 (all checked against the original bytes first):
  FRAY.DOS  + page-3 stub and boot loader (fdd.asm PART 1); 0106h kernel copy length, 0154h JP init; size in the directory
  file 7    2AB9h (the game's only Kanji-ROM read)    -> JP g7
  file 14   ADFEh (the ending's copy of that routine)  -> JP g14
  file 13   4113h / 4245h: sector cache ends at index 3D0h in both sound modes (was (mapper size)*32), which frees
            segment 1Fh and segment 1Eh from offset 2000h (MIDI songs end at 3C9h)
  sectors 550h..: the font, in the unused area 550h-577h (the INF catalogue ends at 54Dh, the save slots start at 578h)
The glyph list is ../phase0/glyphscan/glyphset.json (the supported release). The web app (hdtool/webapp, buildFdd) makes
the same disk 1 from the same rules: assemble() output goes to its assets, patch_disk1() is ported line by line.
"""
import json
import os
import re
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', 'cart'))
import mkcart          # noqa: E402  (ZX0 compressor, sjasmplus path)

DISK = 737280
SEC = 512
FONTSEC = 0x550
FONTMAX = 0x578 - FONTSEC          # 40 sectors up to the save slots
BLK = 40                           # glyphs per compressed block (buffer BLK*32 bytes)
SEG1E = 0x6000                     # segment 1Eh offset 2000h, mapped in page 1
FRAY_SEC, FRAY_LEN = 14, 0xCA2
GLYPHS = os.path.join(HERE, '..', 'phase0', 'glyphscan', 'glyphset.json')


def glyph_list():
    return json.load(open(GLYPHS))['glyphs']


def assemble(nglyph):
    """-> dict: loader (FRAY.DOS tail), code (segment 1Fh from 8000h), symbols; all independent of the font bytes"""
    nblk = -(-nglyph // BLK)
    out = {}
    with tempfile.TemporaryDirectory() as tmp:
        for part in (1, 2):
            open(os.path.join(tmp, 'fdd_def.inc'), 'w').write(
                f'PART equ {part}\nBLK equ {BLK}\nNGLYPH equ {nglyph}\nNBLK equ {nblk}\n')
            r = subprocess.run([mkcart.SJASM, '--nologo', '--msg=war', '--sym=fdd.sym', f'-I{tmp}', f'-I{HERE}',
                                os.path.join(HERE, 'fdd.asm')], cwd=tmp, capture_output=True, text=True)
            if r.returncode:
                sys.exit(r.stdout + r.stderr)
            for m in re.finditer(r'^(\w+):\s+EQU\s+0x([0-9A-Fa-f]+)', open(os.path.join(tmp, 'fdd.sym')).read(), re.M):
                out[m.group(1)] = int(m.group(2), 16)
        out['loader'] = open(os.path.join(tmp, 'loader.bin'), 'rb').read()
        out['code'] = open(os.path.join(tmp, 'font1f.bin'), 'rb').read()
    out.update(blk=BLK, nglyph=nglyph, nblk=nblk, fontsec=FONTSEC, fontmax=FONTMAX, seg1e=SEG1E)
    return out


def font_images(K, glyphs, A, zx0):
    """-> (segment 1Fh image from 8000h, segment 1Eh image from SEG1E). zx0(bytes) -> bytes."""
    bst = [0] * 33
    for g in glyphs:
        bst[(g >> 8) + 1] += 1
    for i in range(32):
        bst[i + 1] += bst[i]
    blocks = [zx0(b''.join(K[g * 32:g * 32 + 32] for g in glyphs[i:i + BLK])) for i in range(0, len(glyphs), BLK)]
    img1f = bytearray(A['code'].ljust(A['DATA'] - 0x8000, b'\0'))
    for v in bst:
        img1f += bytes([v & 0xFF, v >> 8])
    img1f += bytes(g & 0xFF for g in glyphs)
    tab = len(img1f)
    img1f += bytes(3 * len(blocks))
    img1e = bytearray()
    for i, b in enumerate(blocks):
        if not img1e and 0x8000 + len(img1f) + len(b) <= A['BUF']:
            addr, seg = 0x8000 + len(img1f), 0
            img1f += b
        else:
            addr, seg = SEG1E + len(img1e), 1
            img1e += b
        img1f[tab + 3 * i:tab + 3 * i + 3] = bytes([addr & 0xFF, addr >> 8, seg])
    if SEG1E + len(img1e) > 0x8000:
        raise ValueError('font does not fit in segment 1Eh')
    return bytes(img1f), bytes(img1e)


def patch(disk, off, orig, new, what):
    if bytes(disk[off:off + len(orig)]) != orig:
        raise ValueError(f'{what}: the bytes on disk 1 do not match - this is not the supported release')
    disk[off:off + len(new)] = new


def patch_disk1(d1, K, glyphs, A, zx0):
    """patch disk 1 (bytearray) in place; returns a one-line summary"""
    w = lambda v: bytes([v & 0xFF, v >> 8])
    img1f, img1e = font_images(K, glyphs, A, zx0)
    n1, n2 = -(-len(img1f) // SEC), -(-len(img1e) // SEC)
    if n1 + n2 > FONTMAX:
        raise ValueError(f'font needs {n1 + n2} sectors, {FONTMAX} free')
    loader = bytearray(A['loader'])
    base = 0x0DA2                                         # page-0 address of the loader's first byte
    loader[A['n1imm'] + 1 - base] = n1
    loader[A['n2sec'] + 1 - base:A['n2sec'] + 3 - base] = w(FONTSEC + n1)
    loader[A['n2imm'] + 1 - base] = n2
    fray = FRAY_SEC * SEC
    if len(loader) + FRAY_LEN > 7 * SEC:
        raise ValueError('FRAY.DOS would outgrow its 7 sectors')
    patch(d1, 7 * SEC, b'FRAY    DOS', b'FRAY    DOS', 'directory')
    patch(d1, 7 * SEC + 28, w(FRAY_LEN) + b'\0\0', w(FRAY_LEN + len(loader)) + b'\0\0', 'FRAY.DOS size')
    patch(d1, fray + 0x0006, b'\x01\x47\x09', b'\x01' + w(0x947 + A['STUBLEN']), 'FRAY.DOS 0106h')
    patch(d1, fray + 0x0054, b'\xc3\x00\xe0', b'\xc3' + w(A['init']), 'FRAY.DOS 0154h')
    d1[fray + FRAY_LEN:fray + FRAY_LEN + len(loader)] = loader
    patch(d1, 82 * SEC + 0x2AB9 - 0x100, b'\x7d\x29\x29', b'\xc3' + w(A['g7']), 'file 7 2AB9h')
    patch(d1, 238 * SEC + 0xADFE - 0x8000, b'\x7d\x29\x29', b'\xc3' + w(A['g14']), 'file 14 ADFEh')
    patch(d1, 228 * SEC + 0x113, bytes.fromhex('3a2443c6102e20cdee50'), bytes.fromhex('3a244321d00300000000'),
          'file 13 4113h')
    patch(d1, 228 * SEC + 0x245, bytes.fromhex('c6102e20cdee50'), bytes.fromhex('21d00300000000'), 'file 13 4245h')
    area = bytes(d1[FONTSEC * SEC:(FONTSEC + FONTMAX) * SEC])
    if area.count(area[0]) != len(area):
        raise ValueError('sectors 550h-577h of disk 1 are not empty - this is not the supported release')
    img = img1f.ljust(n1 * SEC, b'\0') + img1e.ljust(n2 * SEC, b'\0')
    d1[FONTSEC * SEC:FONTSEC * SEC + len(img)] = img
    return (f'{len(glyphs)} glyphs in {-(-len(glyphs) // BLK)} blocks, font sectors {FONTSEC:03X}h+{n1}+{n2}, '
            f'FRAY.DOS +{len(loader)} bytes')


def read_disks(path):
    out = []
    for n in range(1, 9):
        for name in (f'D{n}.dsk', f'I-City(k)({n}-8).dsk'):
            p = os.path.join(path, name)
            if os.path.exists(p):
                d = open(p, 'rb').read()
                if len(d) != DISK:
                    sys.exit(f'{p}: not a 720KB image')
                out.append(bytearray(d))
                break
        else:
            sys.exit(f'disk {n} not found in {path}')
    if out[0][3:10] != b'IPROJ01':
        sys.exit('disk 1 label is not IPROJ01')
    return out


def zx0_cached():
    tool = mkcart.zx0tool()
    cache = os.path.join(os.path.expanduser('~'), '.cache', 'icity_zx0', 'v22')
    os.makedirs(cache, exist_ok=True)
    return lambda b: mkcart.zx0(b, tool, cache)


def main():
    if len(sys.argv) != 4:
        sys.exit(__doc__)
    disks = read_disks(sys.argv[1])
    K = open(sys.argv[2], 'rb').read()
    if len(K) != 262144:
        sys.exit('KANJI.rom must be 262144 bytes')
    glyphs = glyph_list()
    A = assemble(len(glyphs))
    try:
        print(patch_disk1(disks[0], K, glyphs, A, zx0_cached()))
    except ValueError as e:
        sys.exit(str(e))
    os.makedirs(sys.argv[3], exist_ok=True)
    for n, d in enumerate(disks, 1):
        open(os.path.join(sys.argv[3], f'D{n}.dsk'), 'wb').write(d)


if __name__ == '__main__':
    main()
