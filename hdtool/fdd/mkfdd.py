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
  sectors FONTSEC..: the font (fdd.asm PART 2), in the unused area 550h-577h (the INF catalogue ends at 54Dh, the save
            slots start at 578h)
"""
import os
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', 'cart'))
sys.path.insert(0, os.path.join(HERE, '..', 'phase0', 'glyphscan'))
import mkcart          # noqa: E402  (ZX0 compressor, sjasmplus path)
import glyphscan       # noqa: E402

DISK = 737280
FONTSEC = 0x550
FONTMAX = 0x578 - FONTSEC          # 40 sectors up to the save slots
BLK = 40                           # glyphs per compressed block (buffer BLK*32 bytes)
CODE_EST = 0x140                   # fdd.asm PART 2 code before the data (ASSERTs catch a wrong estimate)
FRAY_SEC, FRAY_LEN = 14, 0xCA2
F7_SEC, F13_SEC, F14_SEC = 82, 228, 238


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


def patch(disk, off, orig, new, what):
    if bytes(disk[off:off + len(orig)]) != orig:
        sys.exit(f'{what}: unexpected bytes {bytes(disk[off:off + len(orig)]).hex()} (want {orig.hex()})')
    disk[off:off + len(new)] = new


def asm(tmp, part, inc):
    open(os.path.join(tmp, 'fdd_layout.inc'), 'w').write(inc)
    r = subprocess.run([mkcart.SJASM, f'-DPART={part}', '--nologo', '--msg=war', '--sym=fdd.sym',
                        '--lst=fdd.lst', f'-I{tmp}', f'-I{HERE}', os.path.join(HERE, 'fdd.asm')],
                       cwd=tmp, capture_output=True, text=True)
    if r.returncode:
        sys.exit(r.stdout + r.stderr)
    sym = {}
    for line in open(os.path.join(tmp, 'fdd.sym')):
        if ':' in line and 'EQU' in line.upper():
            name, val = line.split(':', 1)
            sym[name.strip()] = int(val.split()[-1].rstrip('hH'), 16)
    return sym


def font_layout(K, glyphs):
    """-> (FONTDATA, FONTDATA2 macro text)"""
    tool = mkcart.zx0tool()
    cache = os.path.join(os.path.expanduser('~'), '.cache', 'icity_zx0', 'v22')
    os.makedirs(cache, exist_ok=True)
    buckets = [0] * 33
    for g in glyphs:
        buckets[(g >> 8) + 1] += 1
    for i in range(32):
        buckets[i + 1] += buckets[i]
    lows = [g & 0xFF for g in glyphs]
    blocks = [mkcart.zx0(b''.join(K[g * 32:g * 32 + 32] for g in glyphs[i:i + BLK]), tool, cache)
              for i in range(0, len(glyphs), BLK)]
    tables = 2 * 33 + len(lows) + 3 * len(blocks)
    cap1 = 0xC000 - BLK * 32 - (0x8000 + CODE_EST + tables)
    seg, used = [], 0
    for b in blocks:
        s = 0 if used + len(b) <= cap1 and not (seg and seg[-1]) else 1
        seg.append(s)
        used += len(b) if s == 0 else 0
    db = lambda b: ''.join(f'        db {",".join(str(x) for x in b[i:i + 32])}\n' for i in range(0, len(b), 32))
    m1 = ('        MACRO FONTDATA\nBST:\n' + ''.join(f'        dw {x}\n' for x in buckets) + 'LOWS:\n' + db(lows) +
          'BTAB:\n' + ''.join(f'        dw blk{i}\n        db {s}\n' for i, s in enumerate(seg)) +
          ''.join(f'blk{i}:\n' + db(b) for i, b in enumerate(blocks) if seg[i] == 0) + '        ENDM\n')
    m2 = ('        MACRO FONTDATA2\n' + ''.join(f'blk{i}:\n' + db(b) for i, b in enumerate(blocks) if seg[i] == 1) +
          '        ENDM\n')
    return m1 + m2, sum(map(len, blocks)), seg.count(1)


def main():
    if len(sys.argv) != 4:
        sys.exit(__doc__)
    disks = read_disks(sys.argv[1])
    K = open(sys.argv[2], 'rb').read()
    if len(K) != 262144:
        sys.exit('KANJI.rom must be 262144 bytes')
    codes, _ = glyphscan.scan(sys.argv[1] if all(os.path.exists(os.path.join(sys.argv[1], f'D{n}.dsk'))
                                                 for n in range(1, 9)) else _dump(disks))
    glyphs = sorted({glyphscan.glyph(c) for c in codes if K[glyphscan.glyph(c) * 32:glyphscan.glyph(c) * 32 + 32]
                     .count(0) != 32})
    data, packed, n1e = font_layout(K, glyphs)
    d1 = disks[0]
    with tempfile.TemporaryDirectory() as tmp:
        base = f'        DEFINE BLK {BLK}\n'
        asm(tmp, 2, base + 'FONTSEC equ 0\nN1 equ 0\nN2 equ 0\n' + data)
        f1f = open(os.path.join(tmp, 'font1f.bin'), 'rb').read()
        f1e = open(os.path.join(tmp, 'font1e.bin'), 'rb').read()
        n1, n2 = -(-len(f1f) // 512), -(-len(f1e) // 512)
        if n1 + n2 > FONTMAX:
            sys.exit(f'font needs {n1 + n2} sectors, {FONTMAX} free')
        sym = asm(tmp, 1, base + f'FONTSEC equ {FONTSEC}\nN1 equ {n1}\nN2 equ {n2}\n' + data)
        loader = open(os.path.join(tmp, 'loader.bin'), 'rb').read()
    w = lambda v: bytes([v & 0xFF, v >> 8])
    # FRAY.DOS: append stub + loader, longer kernel copy, JP init
    fray = FRAY_SEC * 512
    if len(loader) + FRAY_LEN > 7 * 512:
        sys.exit('FRAY.DOS would outgrow its 7 sectors')
    patch(d1, fray + FRAY_LEN, bytes(d1[fray + FRAY_LEN:fray + FRAY_LEN + len(loader)]), loader, 'FRAY.DOS tail')
    patch(d1, fray + 0x0106 - 0x100, b'\x01\x47\x09', b'\x01' + w(0x947 + sym['STUBLEN']), 'FRAY.DOS 0106h')
    patch(d1, fray + 0x0154 - 0x100, b'\xc3\x00\xe0', b'\xc3' + w(sym['init']), 'FRAY.DOS 0154h')
    dirent = 7 * 512                                     # root directory, first entry = FRAY.DOS
    patch(d1, dirent, b'FRAY    DOS', b'FRAY    DOS', 'directory')
    patch(d1, dirent + 28, w(FRAY_LEN) + b'\0\0', w(FRAY_LEN + len(loader)) + b'\0\0', 'FRAY.DOS size')
    # the game's glyph reads
    patch(d1, F7_SEC * 512 + 0x2AB9 - 0x100, b'\x7d\x29\x29', b'\xc3' + w(sym['g7']), 'file 7 2AB9h')
    patch(d1, F14_SEC * 512 + 0xADFE - 0x8000, b'\x7d\x29\x29', b'\xc3' + w(sym['g14']), 'file 14 ADFEh')
    # sector cache end 3C8h (file 13 at 4000h)
    patch(d1, F13_SEC * 512 + 0x113, bytes.fromhex('3a2443c6102e20cdee50'), bytes.fromhex('3a2443' '21d003' '00000000'),
          'file 13 4113h')
    patch(d1, F13_SEC * 512 + 0x245, bytes.fromhex('c6102e20cdee50'), bytes.fromhex('21d003' '00000000'), 'file 13 4245h')
    # font
    area = bytes(d1[FONTSEC * 512:(FONTSEC + n1 + n2) * 512])
    if area.count(area[0]) != len(area):
        sys.exit('font area on disk 1 is not empty')
    img = f1f.ljust(n1 * 512, b'\0') + f1e.ljust(n2 * 512, b'\0')
    d1[FONTSEC * 512:FONTSEC * 512 + len(img)] = img
    out = sys.argv[3]
    os.makedirs(out, exist_ok=True)
    for n, d in enumerate(disks, 1):
        open(os.path.join(out, f'D{n}.dsk'), 'wb').write(d)
    print(f'{len(glyphs)} glyphs, {packed} bytes in {-(-len(glyphs) // BLK)} blocks ({n1e} in segment 1Eh); '
          f'font sectors {FONTSEC:03X}h+{n1}+{n2}; FRAY.DOS +{len(loader)} bytes '
          f'(stub {sym["STUBLEN"]}, g7 {sym["g7"]:04X}h, g14 {sym["g14"]:04X}h, init {sym["init"]:04X}h)')


def _dump(disks):
    t = tempfile.mkdtemp()
    for n, d in enumerate(disks, 1):
        open(os.path.join(t, f'D{n}.dsk'), 'wb').write(d)
    return t


if __name__ == '__main__':
    main()
