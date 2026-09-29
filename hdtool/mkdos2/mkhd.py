#!/usr/bin/env python3
"""mkhd.py - build a small FAT12 hard-disk image for openMSX (Sunrise IDE / Nextor) tests.

usage: mkhd.py <out.dsk> <sys dir> [<tree dir> ...] [--mb N]

<sys dir>  holds the DOS system files to copy to the root (NEXTOR.SYS/MSXDOS2.SYS,
           COMMAND2.COM, ...) and boot720.bin (an MSX boot sector whose Z80 code at
           1Eh-1FFh is reused; the BPB comes from mformat).
<tree dir> directories whose *contents* are copied recursively to the root (mkdos2 output; chunks.inc and
           manifest.json are skipped).

Geometry: 16 heads x 32 sectors, size a whole number of cylinders (the Sunrise IDE BIOS
needs that), FAT12 so the ASCII DOS2 2.31 kernel can read it too (PHASE0_FINDINGS section 4).
"""
import sys, os, subprocess, shutil

def run(*a):
    r = subprocess.run(a, capture_output=True, text=True)
    if r.returncode:
        raise SystemExit(f"{' '.join(a)}\n{r.stdout}{r.stderr}")
    return r.stdout

def main():
    args = sys.argv[1:]
    mb = 16
    if "--mb" in args:
        i = args.index("--mb"); mb = int(args[i+1]); del args[i:i+2]
    if len(args) < 2: raise SystemExit(__doc__)
    out, sysdir, trees = args[0], args[1], args[2:]
    cyl = mb * 1024 * 1024 // (16 * 32 * 512)
    total = cyl * 16 * 32
    if os.path.exists(out): os.remove(out)
    with open(out, "wb") as f: f.truncate(total * 512)
    # FAT12: 16 sectors/cluster keeps clusters < 4085 up to 32MB
    spc = 16 if mb > 8 else 8
    run("mformat", "-i", out, "-T", str(total), "-h", "16", "-s", "32", "-c", str(spc), "-M", "512", "-r", "8", "-v", "ICITYDOS2", "::")
    boot = open(os.path.join(sysdir, "boot720.bin"), "rb").read()
    with open(out, "r+b") as f:
        f.seek(0x1E); f.write(boot[0x1E:0x200])
        f.seek(0); f.write(b"\xEB\xFE\x90")          # JMP $ as DOS expects
    for nm in ("NEXTOR.SYS", "MSXDOS2.SYS", "COMMAND2.COM", "COMMAND.COM", "MSXDOS.SYS"):
        p = os.path.join(sysdir, nm)
        if os.path.exists(p): run("mcopy", "-i", out, p, "::" + nm)
    for t in trees:
        for entry in sorted(os.listdir(t)):
            if entry in ("chunks.inc", "manifest.json", "root") or entry.endswith(".dsk"): continue
            run("mcopy", "-i", out, "-s", os.path.join(t, entry), "::")
    print(run("mdir", "-i", out, "::").strip().splitlines()[-1])
    print(f"wrote {out}: {mb}MB, {cyl} cylinders, {total} sectors, FAT12 {spc} sec/cluster")

if __name__ == "__main__":
    main()
