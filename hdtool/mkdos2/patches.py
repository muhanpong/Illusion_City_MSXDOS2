"""Game-side binary patches applied by mkdos2.py (PLAN_BINPATCH.md section 2).

Each entry: id, disk ("1".."8"/"U"), sector (absolute), offset in sector, orig bytes, new bytes.
mkdos2.py refuses to run if orig does not match the disk image.

FRAY.DOS is at disk 1 sectors 14.. (memory 0100h = sector 14 offset 0), so a memory address
A maps to sector 14 + (A-0x100)//512, offset (A-0x100)%512.  The resident kernel image inside
FRAY.DOS sits at 045Bh and is copied to E000h, so kernel address K is file address K-E000h+045Bh.
file13 (MIDI cache module) is at disk 1 sectors 228.. loaded at 4000h.

get_patches(midi=True) adds the MIDI-mode patches (K2, M1-M3) and N=13h; the launcher must then be
built with N_SEG=19 (icity.asm, -DN_SEG=19).  MIDI song reads are tagged "drive 80h" (force disk 1).
"""

def fray(addr):
    o = addr - 0x100
    return 14 + o // 512, o % 512

def kern(addr):                      # FRAY.DOS resident kernel, E000h-based
    return fray(addr - 0xE000 + 0x45B)

def file13(addr):
    o = addr - 0x4000
    return 228 + o // 512, o % 512

TBL = 0xE960                         # logical->physical segment table (32 bytes) in game page 3
INIT_MAP = 0xDA2                     # appended after FRAY.DOS (file length 0CA2h)
INIT_MAP_N = INIT_MAP + 0x14         # the LD A,N immediate the launcher fills in

# init_map: replaces loader 035Bh (mapper probe).  Same effect as 039C-03AB plus E8F3=20h, A=N.
INIT_MAP_CODE = bytes([
    0x21, 0xEB, 0xE8,        # LD HL,E8EBh
    0x06, 0x03,              # LD B,3
    0x70,                    # .l: LD (HL),B      ; logical segment for page B
    0x23,                    # INC HL
    0x36, 0x83,              # LD (HL),83h      ; slot byte (primary mapper)
    0x23,                    # INC HL
    0x05,                    # DEC B
    0xF2, 0xA7, 0x0D,        # JP P,.l   (0DA7h)
    0x3E, 0x20,              # LD A,20h
    0x32, 0xF3, 0xE8,        # LD (E8F3h),A    ; every logical number < E8F3 -> primary path
    0x3E, 0x10,              # LD A,N          ; +14h: N written by the launcher (10h FM, 13h MIDI)
    0x32, 0xF5, 0xE8,        # LD (E8F5h),A    ; the loader's own store is patched away (L1)
    0xC9,                    # RET
])


assert INIT_MAP_CODE[0x14] == 0x10 and INIT_MAP_CODE[0x0B:0x0E] == bytes([0xF2, 0xA7, 0x0D])

def P(id, secoff, orig, new):
    s, o = secoff
    assert len(orig) == len(new), id
    return {"id": id, "disk": "1", "sector": s, "offset": o, "orig": bytes(orig), "new": bytes(new)}

G1_ORIG = bytes.fromhex("7d29296fcb7420040ed91802" "0edb" "ed610ded690c2100d50620edb2c9")

def pad(b, n):
    assert len(b) <= n, (len(b), n)
    return bytes(b) + bytes(n - len(b))

def get_patches(midi, font=False):
    pl = [
        # L1: loader 010E-0116.  Original: CALL E015 (reads sector 11 via F37D); CALL 035B (mapper probe,
        # writes AA/55 into every segment); LD (E8F5),A.  New: CALL init_map first so E8EB/E8F3/E8F5 are
        # valid before the first F37D request, then CALL E015, then LD A,(E8F5) for the CP 11h that follows.
        P("L1", fray(0x010E), bytes.fromhex("cd15e0cd5b0332f5e8"),
          bytes([0xCD, INIT_MAP & 0xFF, INIT_MAP >> 8, 0xCD, 0x15, 0xE0, 0x3A, 0xF5, 0xE8])),
        # L4: CHGCPU 81h (R800 ROM) -> 82h (R800 DRAM): stay in the mode DOS2 booted with
        P("L4", fray(0x01F2), bytes.fromhex("3e81"), bytes.fromhex("3e82")),
        # K1: E266-E275 logical->physical via TBL instead of (E8F3)/(E8F4) arithmetic
        P("K1", kern(0xE266), bytes.fromhex("5f3af3e8577b92573e8338045a3af4e8"),
          bytes([0xE5, 0x21, TBL & 0xFF, TBL >> 8, 0x85, 0x6F, 0x5E, 0xE1, 0x3E, 0x83]) + bytes(6)),
        # INIT: init_map code appended at 0DA2h (bytes there are leftovers past the file length)
        P("INIT", fray(INIT_MAP), bytes.fromhex("52085308540855085608ffff5808ffff5a085b085c085d085e"),
          INIT_MAP_CODE),
    ]
    if midi:
        # K2: disk-read wrapper E60B: skip the sector-cache module, always straight to F37D
        pl.append(P("K2", kern(0xE60B), bytes.fromhex("3af5e8fe11da7df3"), bytes.fromhex("c37df30000000000")))
        # M1: file13 4145 (song preload loop, 45 bytes): do not read, only advance the cache index by the
        #     song's sector count (4387) so the index table 4333h comes out exactly as in the original.
        m1 = bytes([0x2A, 0x2E, 0x43,          # LD HL,(432E)
                    0x3A, 0x87, 0x43,          # LD A,(4387)
                    0x5F, 0x16, 0x00, 0x19,    # LD E,A / LD D,0 / ADD HL,DE
                    0x22, 0x2E, 0x43,          # LD (432E),HL
                    0xAF, 0x32, 0x87, 0x43,    # XOR A / LD (4387),A
                    0xC9])
        pl.append(P("M1", file13(0x4145),
                    bytes.fromhex("2a2e43cd8c422230430602cd30e03e01210080ed5b304319ebcdab42cd33e02a2e4323222e433a8743b720d4c9"),
                    pad(m1, 45)))
        # M2: file13 42E9 (fetch next 512-byte cache sector into F400h, 56 bytes): read it from disk 1 instead.
        #     sector = index + (0152h - 0250h); L=80h in the F37D call means "force disk 1" (songs live there).
        m2 = bytes([0xF5, 0xC5, 0xD5, 0xE5, 0xDD, 0xE5, 0xFD, 0xE5,   # push af,bc,de,hl,ix,iy
                    0x11, 0x00, 0xF4, 0x0E, 0x1A, 0xCD, 0x7D, 0xF3,   # LD DE,F400 / LD C,1A / CALL F37D
                    0x2A, 0x2E, 0x43, 0x11, 0x02, 0xFF, 0x19, 0xEB,   # LD HL,(432E) / LD DE,FF02 / ADD HL,DE / EX DE,HL
                    0x21, 0x80, 0x01, 0x0E, 0x2F, 0xCD, 0x7D, 0xF3,   # LD HL,0180 (H=1, L=80h) / LD C,2F / CALL F37D
                    0xFB,                                              # EI
                    0x2A, 0x2E, 0x43, 0x23, 0x22, 0x2E, 0x43,         # index++
                    0xFD, 0xE1, 0xDD, 0xE1, 0xE1, 0xD1, 0xC1, 0xF1, 0xC9])
        m2_orig = bytes.fromhex("f5c5d5e5dde5fde52a2e43cd8c422230430602cd30e02a3043110080191100f4010002edb0cd33e0ed5b2e4313ed532e43fde1dde1e1d1c1f1c9")
        pl.append(P("M2", file13(0x42E9), m2_orig, pad(m2, len(m2_orig))))
        # M3: file13 40AC: index for the init data.  The init entry (014Ah, 8 sectors) sits 8 sectors before
        #     song 0 (0152h) on disk, so start the index 8 lower (0248h -> sector 014Ah).
        pl.append(P("M3", file13(0x40AC), bytes.fromhex("115002"), bytes.fromhex("114802")))
    # P1-P6: file9 (disk 1 sectors 156.., memory 4000h) save-list paging -> icity.asm cbk/fixno/fixsel/newlist/secof
    #        (96 slots per disk, left/right pages; addresses checked by ASSERTs in icity.asm)
    w = lambda a: bytes([a & 0xFF, a >> 8])
    f9 = lambda a: (156 + (a - 0x4000) // 512, (a - 0x4000) % 512)
    CBK, FIXNO, FIXSEL, NEWLIST, SECOF = 0xE9AA, 0xE9F7, 0x00F6, 0xE9EA, 0xE9DB
    pl.append(P("P1", f9(0x590A), bytes.fromhex("210000"), b"\x21" + w(CBK)))
    pl.append(P("P2", f9(0x5957), bytes.fromhex("326ad5"), b"\xcd" + w(FIXNO)))
    pl.append(P("P3", f9(0x5910), bytes.fromhex("32c55e"), b"\xcd" + w(FIXSEL)))
    pl.append(P("P4", f9(0x58E3), bytes.fromhex("cd4459"), b"\xcd" + w(NEWLIST)))
    pl.append(P("P5", f9(0x5A66), bytes.fromhex("2178051919"), b"\xcd" + w(SECOF) + bytes(2)))
    pl.append(P("P6", f9(0x5A8F), bytes.fromhex("2178051919"), b"\xcd" + w(SECOF) + bytes(2)))
    if font:
        # G1: file7 2AB9h (memory address = file offset + 0100h), the game's only Kanji-ROM access, 28 bytes:
        #     LD A,L / ADD HL,HL / ADD HL,HL / LD L,A / BIT 6,H / JR NZ / LD C,D9 / JR / LD C,DB /
        #     OUT (C),H / DEC C / OUT (C),L / INC C / LD HL,D500 / LD B,20 / INIR / RET
        #     -> JP E980h: the glyph wrapper the launcher installs in game page 3; it asks the launcher for the
        #     glyph (function 50h) which reads \ICITY\FONT.BIN (same layout as KANJI.rom) through a cache.
        pl.append(P("G1", (82 + 0x29B9 // 512, 0x29B9 % 512), G1_ORIG, pad(bytes([0xC3, 0x80, 0xE9]), 28)))
    return pl

PATCHES = get_patches(False)
