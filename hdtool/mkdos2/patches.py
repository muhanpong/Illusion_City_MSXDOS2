"""Game-side binary patches applied by mkdos2.py (PLAN_BINPATCH.md section 2).

Each entry: id, disk ("1".."8"/"U"), sector (absolute), offset in sector, orig bytes, new bytes.
mkdos2.py refuses to run if orig does not match the disk image.

FRAY.DOS is at disk 1 sectors 14.. (memory 0100h = sector 14 offset 0), so a memory address
A maps to sector 14 + (A-0x100)//512, offset (A-0x100)%512.  The resident kernel image inside
FRAY.DOS sits at 045Bh and is copied to E000h, so kernel address K is file address K-E000h+045Bh.
file13 (MIDI cache module) is at disk 1 sectors 228.. loaded at 4000h.

Set MIDI = True to include the MIDI-mode patches (K2, M1-M4); the launcher must then be built
with the matching segment count (13h logical segments).
"""
MIDI = False

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
    0x3E, 0x10,              # LD A,N          ; +14h: N written by the launcher
    0x32, 0xF5, 0xE8,        # LD (E8F5h),A    ; the loader's own store is patched away (L1)
    0xC9,                    # RET
])
assert INIT_MAP_CODE[0x14] == 0x10 and INIT_MAP_CODE[0x0C:0x0E] == bytes([0xA7, 0x0D])

def P(id, secoff, orig, new):
    s, o = secoff
    assert len(orig) == len(new), id
    return {"id": id, "disk": "1", "sector": s, "offset": o, "orig": bytes(orig), "new": bytes(new)}

PATCHES = [
    # L1: loader 010E-0116.  Original: CALL E015 (reads sector 11 via F37D); CALL 035B (mapper probe,
    # writes AA/55 into every segment); LD (E8F5),A.  New: CALL init_map first so E8EB/E8F3/E8F5 are
    # valid before the first F37D request, then CALL E015, then LD A,(E8F5) for the CP 11h that follows.
    P("L1", fray(0x010E), bytes.fromhex("cd15e0cd5b0332f5e8"),
      bytes([0xCD, INIT_MAP & 0xFF, INIT_MAP >> 8, 0xCD, 0x15, 0xE0, 0x3A, 0xF5, 0xE8])),
    # L4: CHGCPU 81h (R800 ROM) -> 82h (R800 DRAM): stay in the mode DOS2 booted with
    P("L4", fray(0x01F2), bytes.fromhex("3e81"), bytes.fromhex("3e82")),
    # K1: E266-E275 logical->physical via TBL instead of (E8F3)/(E8F4) arithmetic
    P("K1", kern(0xE266), bytes.fromhex("5f3af3e8577b9257 3e8338045a3af4e8".replace(" ", "")),
      bytes([0xE5, 0x21, TBL & 0xFF, TBL >> 8, 0x85, 0x6F, 0x5E, 0xE1, 0x3E, 0x83]) + bytes(6)),
    # INIT: init_map code appended at 0DA2h (bytes there are leftovers past the file length)
    P("INIT", fray(INIT_MAP), bytes.fromhex("5208530854085508 5608ffff5808ffff 5a085b085c085d085e".replace(" ", "")),
      INIT_MAP_CODE),
]

if MIDI:
    PATCHES += [
        # K2: disk-read wrapper E60B: skip the sector cache module, always straight to F37D
        P("K2", kern(0xE60B), bytes.fromhex("3af5e8fe11da7df3"), bytes.fromhex("c37df30000000000")),
        # M1-M4: file13 on-demand song loading - to be written (PLAN_BINPATCH.md 2-3)
    ]
