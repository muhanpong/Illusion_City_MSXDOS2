#!/usr/bin/env python3
"""mkdos2.py - split the Illusion City disks into chunk files for the MSX-DOS2 launcher.

usage: mkdos2.py <disk dir> <out dir> [--merge N] [--no-patch] [--fm-only] [--font FONT.BIN]

<disk dir> holds I-City(k)(1-8).dsk .. (8-8).dsk (or D1.dsk..D8.dsk) and the user disk
(I-City(k)(U).dsk / DU.dsk / userdisk.DSK).  Output tree:

    <out>/ICITY/D1/D1_0000.DAT ...    game disk n, chunk starting at sector 0000h
    <out>/ICITY/DU/DU_0000.DAT ...    user disk
    <out>/ICITY/SAVE/D1_0578.DAT      save slots (disk 1), DU_0578.DAT (user disk)
    <out>/chunks.inc                  sjasmplus include: per-disk sorted start-sector tables
    <out>/manifest.json               everything the tool knows (ranges, chunks, patches)

Chunk boundaries come from every (start, length) range the game can ask for:
sector-11 file table, INF catalogue (file 6: name records + tail table), the fixed
system area (0-13) and the save area (578h-587h).  Chunks tile the whole disk with no
holes, so a request is always "file + offset" and never needs zero fill.  Overlapping
ranges just produce more boundaries; correctness does not depend on the range list
being complete.

--font FONT.BIN replaces the Kanji ROM: patch G1 sends the game's glyph reads to the launcher, which serves them from
ICITY\\FONT.BIN (262144 bytes, KANJI.rom layout) through a cache.  Without it the game keeps using the machine's ROM.

Binary patches (PLAN_BINPATCH.md section 2) are applied to the chunk data after
splitting and verified against the original bytes; the reassembly check then compares
everything except the patched bytes.
"""
import sys, os, json, struct, glob
from patches import get_patches

SEC = 512
DISK_SECTORS = 1440
SAVE_START, SAVE_LEN = 0x578, 0x10
SYS_LEN = 14                      # boot sector, FAT, directory (sector 11 = file table)

def find_disk(d, n):
    names = [f"I-City(k)({n}-8).dsk", f"D{n}.dsk", f"d{n}.dsk"] if n != "U" else \
            ["I-City(k)(U).dsk", "DU.dsk", "userdisk.DSK", "userdisk.dsk"]
    for nm in names:
        p = os.path.join(d, nm)
        if os.path.exists(p): return p
    raise SystemExit(f"disk {n} not found in {d} (tried {names})")

def file_table(img):
    t = img[11*SEC:12*SEC]
    out = []
    for i in range(256):
        st, cnt = t[2*i], t[2*i+1]
        if st == 0 and cnt == 0: break
        out.append((st, cnt))
    return out

def inf_ranges(img, ftab):
    """Ranges from the INF catalogue (file 6).  Returns (named, tail, info)."""
    st, cnt = ftab[6]
    inf = img[st*SEC:(st+cnt)*SEC]
    if inf[:4] != b"INF\0":
        return [], [], {"present": False}
    used = struct.unpack_from("<H", inf, 4)[0]
    namelen = struct.unpack_from("<H", inf, 6)[0]
    named, tail = [], []
    nrec = namelen // 26
    assert nrec * 26 == namelen, namelen
    for r in range(nrec):
        rec = inf[0x20 + 26*r: 0x20 + 26*r + 26]
        name = rec[:3].decode("latin1")
        for k in range(7):
            s, l = struct.unpack_from("<HB", rec, 3 + 3*k)
            if l: named.append((s, l, name))
    pos = 0x20 + namelen
    while pos + 3 <= used:
        s, l = struct.unpack_from("<HB", inf, pos)
        if l: tail.append((s, l, f"tail@{pos:03X}"))
        pos += 3
    return named, tail, {"present": True, "used": used, "records": nrec, "tail_entries": len(tail)}

def chunk_bounds(ranges, fixed):
    b = set()
    for s, l, *_ in ranges:
        assert 0 <= s and s + l <= DISK_SECTORS, (s, l)
        b.add(s); b.add(s + l)
    for s, l in fixed:
        b.add(s); b.add(s + l)
    b.add(0); b.add(DISK_SECTORS)
    return sorted(b)

def merge_small(bounds, fixed, minlen):
    """Merge chunks shorter than minlen into the previous one, never across a fixed edge."""
    keep = {0, DISK_SECTORS}
    for s, l in fixed: keep.add(s); keep.add(s + l)
    out = [bounds[0]]
    for x in bounds[1:]:
        if x in keep or x - out[-1] >= minlen:
            out.append(x)
        else:
            # dropping x merges [out[-1],x) with [x,next); allowed unless next edge is fixed-short
            pass
    if out[-1] != DISK_SECTORS: out.append(DISK_SECTORS)
    return out

def main():
    args = sys.argv[1:]
    merge = 0; do_patch = True; midi = True
    if "--merge" in args:
        i = args.index("--merge"); merge = int(args[i+1]); del args[i:i+2]
    if "--fm-only" in args:                # without the MIDI-module patches (the launcher's FM-only mode does not need them)
        args.remove("--fm-only"); midi = False
    font = None
    if "--font" in args:
        i = args.index("--font"); font = args[i+1]; del args[i:i+2]
        if os.path.getsize(font) != 0x40000:
            raise SystemExit("font file must be 262144 bytes (KANJI.rom layout: 8192 glyphs x 32 bytes, level 1 then level 2)")
    PATCHES = get_patches(midi, font=bool(font))
    if "--no-patch" in args:
        args.remove("--no-patch"); do_patch = False
    if len(args) != 2:
        raise SystemExit(__doc__)
    src, out = args
    manifest = {"disks": {}, "patches": []}
    inc = ["; generated by mkdos2.py - chunk start sectors per disk (sorted, u16), count first",
           "; a request (disk, sector) maps to the chunk whose start is the largest <= sector",
           ""]
    total_chunks = 0
    disks = [str(n) for n in range(1, 9)] + ["U"]
    images = {}
    for n in disks:
        p = find_disk(src, n)
        img = bytearray(open(p, "rb").read())
        assert len(img) == DISK_SECTORS * SEC, (p, len(img))
        images[n] = img
        tag = f"D{n}"
        ftab = file_table(img) if n != "U" else []
        ranges = [(s, c, f"file{i}") for i, (s, c) in enumerate(ftab) if c]
        named, tail, info = inf_ranges(img, ftab) if n != "U" and len(ftab) > 6 else ([], [], {"present": False})
        ranges += named + tail
        fixed = [(0, SYS_LEN)]
        if n in ("1", "U"): fixed.append((SAVE_START, SAVE_LEN))
        bounds = chunk_bounds(ranges, fixed)
        if merge: bounds = merge_small(bounds, fixed, merge)
        chunks = [(bounds[i], bounds[i+1]) for i in range(len(bounds) - 1)]
        # sanity: tiling
        assert chunks[0][0] == 0 and chunks[-1][1] == DISK_SECTORS
        assert all(a[1] == b[0] for a, b in zip(chunks, chunks[1:]))
        # patches for this disk
        applied = []
        if do_patch:
            for pt in PATCHES:
                if pt["disk"] != n: continue
                off = pt["sector"] * SEC + pt["offset"]
                cur = bytes(img[off:off+len(pt["orig"])])
                if cur != pt["orig"]:
                    raise SystemExit(f"patch {pt['id']}: original bytes mismatch at D{n} sector {pt['sector']:#x}+{pt['offset']:#x}: {cur.hex()} != {pt['orig'].hex()}")
                img[off:off+len(pt["new"])] = pt["new"]
                applied.append(pt["id"])
                manifest["patches"].append({"id": pt["id"], "disk": n, "sector": pt["sector"], "offset": pt["offset"], "len": len(pt["new"])})
        # write chunk files
        dd = os.path.join(out, "ICITY", tag)
        os.makedirs(dd, exist_ok=True)
        os.makedirs(os.path.join(out, "ICITY", "SAVE"), exist_ok=True)
        files = []
        for a, b in chunks:
            name = f"{tag}_{a:04X}.DAT"
            sub = "SAVE" if (a == SAVE_START and n in ("1", "U")) else tag
            path = os.path.join(out, "ICITY", sub, name)
            with open(path, "wb") as f: f.write(img[a*SEC:b*SEC])
            files.append({"start": a, "end": b, "file": f"ICITY\\{sub}\\{name}"})
        total_chunks += len(chunks)
        nz = sum(1 for s in range(DISK_SECTORS) if any(img[s*SEC:(s+1)*SEC]))
        manifest["disks"][tag] = {"source": os.path.basename(p), "file_table": ftab, "inf": info,
                                  "ranges": [(s, l, nm) for s, l, nm in ranges],
                                  "chunks": files, "patches": applied, "nonzero_sectors": nz}
        inc.append(f"chunks_{tag}:")
        inc.append(f"        db {len(chunks)}")
        starts = [a for a, _ in chunks]
        for i in range(0, len(starts), 8):
            inc.append("        dw " + ", ".join(f"{s:04X}h" for s in starts[i:i+8]))
        inc.append("")
        print(f"{tag}: ranges={len(ranges):3d} (files {len([r for r in ranges if r[2].startswith('file')])}, "
              f"named {len(named)}, tail {len(tail)})  chunks={len(chunks):3d}  smallest={min(b-a for a,b in chunks)}  "
              f"largest={max(b-a for a,b in chunks)}  patches={applied}")
    inc.append("chunk_tables:")
    inc.append("        dw " + ", ".join(f"chunks_D{n}" for n in disks))
    with open(os.path.join(out, "chunks.inc"), "w") as f: f.write("\n".join(inc) + "\n")
    with open(os.path.join(out, "manifest.json"), "w") as f: json.dump(manifest, f, indent=1)
    if font:
        import shutil
        os.makedirs(os.path.join(out, "ICITY"), exist_ok=True)
        shutil.copyfile(font, os.path.join(out, "ICITY", "FONT.BIN"))
        print("font:", font, "-> ICITY\\FONT.BIN (patch G1 active: the Kanji ROM is not read)")
    print(f"total chunks {total_chunks}")
    # --- verification: reassemble and compare with the originals (outside patched bytes)
    bad = 0
    for n in disks:
        tag = f"D{n}"
        orig = open(find_disk(src, n), "rb").read()
        re_img = bytearray()
        for c in manifest["disks"][tag]["chunks"]:
            re_img += open(os.path.join(out, c["file"].replace("\\", os.sep)), "rb").read()
        assert len(re_img) == len(orig), tag
        mask = bytearray(orig)
        for pt in manifest["patches"]:
            if pt["disk"] == n:
                off = pt["sector"] * SEC + pt["offset"]
                mask[off:off+pt["len"]] = re_img[off:off+pt["len"]]
        if bytes(mask) != bytes(re_img):
            diff = next(i for i in range(len(orig)) if mask[i] != re_img[i])
            print(f"VERIFY FAIL {tag}: first difference at byte {diff:#x} (sector {diff//SEC:#x})"); bad += 1
    print("verify:", "OK - reassembled disks match originals outside patched bytes" if not bad else f"{bad} disk(s) differ")
    sys.exit(1 if bad else 0)

if __name__ == "__main__":
    main()
