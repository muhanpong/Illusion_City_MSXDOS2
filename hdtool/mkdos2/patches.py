"""Game-side binary patches applied by mkdos2.py (PLAN_BINPATCH.md section 2).

Each entry: id, disk ("1".."8"/"U"), sector (absolute), offset in sector, orig bytes, new bytes.
mkdos2.py refuses to run if orig does not match the disk image.

FRAY.DOS is at disk 1 sectors 14.. (memory 0100h = sector 14 offset 0), so a memory address
A maps to sector 14 + (A-0x100)//512, offset (A-0x100)%512.  file13 (MIDI cache module) is
at disk 1 sectors 228.. loaded at 4000h.

M1 (chunk tool) ships with the table empty; M2+ fill it in.
"""

def fray(addr):
    o = addr - 0x100
    return 14 + o // 512, o % 512

def file13(addr):
    o = addr - 0x4000
    return 228 + o // 512, o % 512

PATCHES = [
]
