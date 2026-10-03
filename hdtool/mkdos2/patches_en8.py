"""Game-side binary patches for the English 8-disc release (MSX Translations), applied by mkdos2.py --en8.

Same idea as patches.py (the launcher replaces the game's mapper probe, its segment arithmetic and, in MIDI mode, the sector-cache
module), but every site moved: the English loader is the eight sectors 0Bh-12h of disk 1 loaded at 0100h (memory address A is
sector 11 + (A-0100h)//512, offset (A-0100h)%512), its kernel image sits at 03D7h and is copied to E000h (so kernel address K is
loader address K-E000h+03D7h), and the kernel variables E8EB/E8F3/E8F5 are E8B1/E8B9/E8BB.  There is no font patch (G1/G2): the
English game never touches the Kanji ROM (measured: no access to ports D8h-DBh from boot through the opening, disk 2 and the ending
intro).  P1-P6 are the Korean build's slot-list paging patches (file 9 sites are identical in the English game): 96 slots per disk, 8 per page.
Every patch states the original bytes; mkdos2.py refuses to run if the disk differs.
"""

def fray(addr):
    o = addr - 0x100
    return 11 + o // 512, o % 512

def kern(addr):                      # resident kernel, E000h-based, image at 03D7h in the loader
    return fray(addr - 0xE000 + 0x3D7)

def file13(addr):                    # MIDI cache module: disk 1 sectors 228.., loaded at 4000h
    o = addr - 0x4000
    return 228 + o // 512, o % 512

TBL = 0xE979                         # logical->physical segment table (32 bytes) in game page 3 (icity.asm EN8)
INIT_MAP = 0x1041                    # free (zero) tail of the loader image, 0100h-10FFh is loaded
INIT_MAP_N = INIT_MAP + 0x14         # the LD A,N immediate the launcher fills in

INIT_MAP_CODE = bytes([
    0x21, 0xB1, 0xE8,        # LD HL,E8B1h
    0x06, 0x03,              # LD B,3
    0x70,                    # .l: LD (HL),B      ; logical segment for page B
    0x23,                    # INC HL
    0x36, 0x83,              # LD (HL),83h      ; slot byte (primary mapper)
    0x23,                    # INC HL
    0x05,                    # DEC B
    0xF2, (INIT_MAP + 5) & 0xFF, (INIT_MAP + 5) >> 8,   # JP P,.l
    0x3E, 0x20,              # LD A,20h
    0x32, 0xB9, 0xE8,        # LD (E8B9h),A    ; every logical number < E8B9 -> primary path
    0x3E, 0x10,              # LD A,N          ; +14h: N written by the launcher (10h FM, 13h MIDI)
    0xC9,                    # RET               ; the loader's own LD (E8BBh),A follows
])
assert INIT_MAP_CODE[0x14] == 0x10 and len(INIT_MAP_CODE) == 22

def P(id, secoff, orig, new):
    s, o = secoff
    assert len(orig) == len(new), id
    return {"id": id, "disk": "1", "sector": s, "offset": o, "orig": bytes(orig), "new": bytes(new)}

def pad(b, n):
    assert len(b) <= n, (len(b), n)
    return bytes(b) + bytes(n - len(b))

def get_patches(midi):
    pl = [
        # L1: loader 0114h CALL 02C4h (mapper probe: writes AA/55 into every segment) -> CALL init_map (A = N, E8B1/E8B9 set)
        P("L1", fray(0x0114), bytes.fromhex("cdc402"), bytes([0xCD, INIT_MAP & 0xFF, INIT_MAP >> 8])),
        # L4: CHGCPU 81h (R800 ROM) -> 82h (R800 DRAM): stay in the mode DOS2 booted with (loader 01D1h)
        P("L4", fray(0x01D1), bytes.fromhex("3e81"), bytes.fromhex("3e82")),
        # K1: kernel E224h logical->physical via TBL instead of (E8B9)/(E8BA) arithmetic
        P("K1", kern(0xE224), bytes.fromhex("5f3ab9e8577b92573e8338045a3abae8"),
          bytes([0xE5, 0x21, TBL & 0xFF, TBL >> 8, 0x85, 0x6F, 0x5E, 0xE1, 0x3E, 0x83]) + bytes(6)),
        # INIT: init_map code in the loader's zero tail
        P("INIT", fray(INIT_MAP), bytes(len(INIT_MAP_CODE)), INIT_MAP_CODE),
    ]
    if midi:
        # K2: disk-read wrapper E5C3h: skip the sector-cache module, always straight to F37D
        pl.append(P("K2", kern(0xE5C3), bytes.fromhex("3abbe8fe11da7df3"), bytes.fromhex("c37df30000000000")))
        # M1 (file13 414Bh): song preload loop; only advance the cache index by the song's sector count (43C3h)
        m1 = bytes([0x2A, 0x6A, 0x43,          # LD HL,(436A)
                    0x3A, 0xC3, 0x43,          # LD A,(43C3)
                    0x5F, 0x16, 0x00, 0x19,    # LD E,A / LD D,0 / ADD HL,DE
                    0x22, 0x6A, 0x43,          # LD (436A),HL
                    0xAF, 0x32, 0xC3, 0x43,    # XOR A / LD (43C3),A
                    0xC9])
        pl.append(P("M1", file13(0x414B),
                    bytes.fromhex("2a6a43cd9b42226c430602cd30e03e01210080ed5b6c4319ebcdba42cd33e02a6a4323226a433ac343b720d4c9"),
                    pad(m1, 45)))
        # M2 (file13 42F8h): fetch the next 512-byte cache sector into F400h; read it from disk 1 instead (sector = index + 0152h-0250h,
        # L=80h means "force disk 1": the songs live there)
        m2 = bytes([0xF5, 0xC5, 0xD5, 0xE5, 0xDD, 0xE5, 0xFD, 0xE5,
                    0x11, 0x00, 0xF4, 0x0E, 0x1A, 0xCD, 0x7D, 0xF3,   # LD DE,F400 / LD C,1A / CALL F37D
                    0x2A, 0x6A, 0x43, 0x11, 0x02, 0xFF, 0x19, 0xEB,   # LD HL,(436A) / LD DE,FF02 / ADD HL,DE / EX DE,HL
                    0x21, 0x80, 0x01, 0x0E, 0x2F, 0xCD, 0x7D, 0xF3,   # LD HL,0180 / LD C,2F / CALL F37D
                    0xFB,
                    0x2A, 0x6A, 0x43, 0x23, 0x22, 0x6A, 0x43,         # index++
                    0xFD, 0xE1, 0xDD, 0xE1, 0xE1, 0xD1, 0xC1, 0xF1, 0xC9])
        m2_orig = bytes.fromhex("f5c5d5e5dde5fde52a6a43cd9b42226c430602cd30e02a6c43110080191100f4010002edb0cd33e0ed5b6a4313ed536a43fde1dde1e1d1c1f1c9")
        pl.append(P("M2", file13(0x42F8), m2_orig, pad(m2, len(m2_orig))))
        # M3 (file13 40AFh): index for the init data, 8 sectors before song 0
        pl.append(P("M3", file13(0x40AF), bytes.fromhex("115002"), bytes.fromhex("114802")))
    # P1-P6: file9 (disk 1 sectors 156.., memory 4000h) save-list paging -> icity.asm cbk/fixno/fixsel/newlist/secof (game page 3)
    w = lambda a: bytes([a & 0xFF, a >> 8])
    f9 = lambda a: (156 + (a - 0x4000) // 512, (a - 0x4000) % 512)
    CBK, NEWLIST, SECOF, FIXNO, FIXSEL = 0xDD3E, 0xDD30, 0xE9D3, 0xE9E2, 0xE9F3
    pl.append(P("P1", f9(0x590A), bytes.fromhex("210000"), b"\x21" + w(CBK)))
    pl.append(P("P2", f9(0x5957), bytes.fromhex("326ad5"), b"\xcd" + w(FIXNO)))
    pl.append(P("P3", f9(0x5910), bytes.fromhex("32c55e"), b"\xcd" + w(FIXSEL)))
    pl.append(P("P4", f9(0x58E3), bytes.fromhex("cd4459"), b"\xcd" + w(NEWLIST)))
    pl.append(P("P5", f9(0x5A66), bytes.fromhex("2178051919"), b"\xcd" + w(SECOF) + bytes(2)))
    pl.append(P("P6", f9(0x5A8F), bytes.fromhex("2178051919"), b"\xcd" + w(SECOF) + bytes(2)))
    return pl
