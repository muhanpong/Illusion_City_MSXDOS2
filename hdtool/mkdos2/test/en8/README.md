# English 8-disc (MSX Translations) DOS2 build - tests

Headless openMSX (`set renderer none`, `SDL_VIDEODRIVER=dummy`), machine `Panasonic_FS-A1GT`, the HD image from `build.sh` with
`-ext SunriseIDE_Nextor` (Nextor) or `-ext ide` (ASCII MSX-DOS2, `SYSDIR=sys_ascii ./build.sh ...`).  The screen is read from VRAM
(`vrdump_png.py`: SCREEN 5 page 0 -> PNG).  The original floppy game is the reference.

| script | what |
|---|---|
| `drive.tcl` | boots the HD, runs `ICITY`, drives the menus by menu IX (8338h sound, 8368h main, 5C19h medium, 5C86h slot list), logs every F37D read/write (`reads.log`), the first 6000 MSX-MIDI bytes (`midi.txt`), VRAM dumps |
| `floppy_run.tcl` + `floppy_reads.tcl` / `floppy_reads_fm.tcl` / `floppy_midi.tcl` | the same menu path on the original floppy game (`fdd/test/run.tcl` + headless), same logs; `_fm` forces FM-only mode (mapper probe result 10h) |
| `cmp_reads.py` | floppy `reads.log` vs DOS2 `reads.log`: every request must be identical (the floppy's two boot reads are skipped) |
| `pair.sh` | one save slot of a Japanese "Data Disk" through both, then `cmp_reads.py` |

## Results (2026-10-03, illuk_EN worktree, sjasmplus 1.24)
- Opening demo (MAIN=2, MIDI+FM image, 300 s): 232 of 232 reads identical (Nextor and ASCII MSX-DOS2).  FM-only image vs floppy forced to FM: 231 of 231.
- All 27 save slots of the four Japanese data disks (user disk = `~/illusion_city/x/ja/ ... (Data Disk 1-4)`, slots 1-8 / 1-8 / 1-8 / 1-3):
  the game enters game disks 2,3,3,3,3,2,4,4 / 2,4,2,5,2,5,2,5 / 6,6,7,7,7,2,7,8 / 8,8,8 exactly like the floppy, 0 mismatching reads in the compared
  window (200 s of game time; where the DOS2 build is slower the compared window is the shorter list).
- MIDI: the first 6000 non-zero bytes written to the MSX-MIDI ports in the opening demo are identical to the floppy's (patches K2, M1-M3).
- Save write: with `INJ` the first user-disk slot read is turned into a write of slot 1's data to sector 57Ah; it lands in `\ICITY\SAVE\DU_0578.DAT`
  (bytes 1024-2047), and a fresh boot loading slot 2 reads exactly the same sectors as slot 1 did.
- Slot list paging (P1-P6, 96 slots per disk, left/right keys or joystick 1 left/right, 8 per page): page 2 shows slots 9-16; slot 1's data written to sector 0600h
  (`INJ`, `INJSEC=1536`) lands at 8KB in `DU_0578.DAT`, shows up as slot 9 on page 2, and loading it (same game disk, same reads from the sector-0 check on, 86/86)
  behaves like slot 1.  All the results above were re-run with the paging patches in.
- A user disk that is all zeros (blank) is accepted (the game treats any disk whose label is not IPROJ01-08/T as the user disk): its slots are empty.

## Facts found while porting (the plan's first guess was wrong on these)
- Game page 0, 003Bh-0054h is **not** free: DOS2's slot-switch helpers sit there (RDSLT/WRSLT/CALSLT/ENASLT in the DOS2 page-3 jump table call them), and the
  game's page-0 segments are copies of the DOS2 page 0.  Only 007Ah-007Fh and 00F8h-00FFh are free (0055h-00F7h is the game's code and width table).
- The page switch therefore keeps only `OUT (FFh),A / LD A,3 / OUT (FCh),A` at 00F8h in the game's page 0 (the hook in game page 3 has already switched pages 2 and 1)
  and `JP leave3` at 007Ch; DOS2's page 0 uses 007Ah-00FFh (the default FCB area and the command line buffer: `OUT (FCh),A` at 007Ah, the DOS2 variables
  at 0080h, continuation/leave routine at 0090h, a `JR` at 00FEh) - the same area the Korean stub used.
- The game's copies of page 0 must start with 0080h-008Fh = 0: the game's interrupt handler reads (0088h)/(0089h) right after the loader's EI and calls code at 8000h
  when (0089h) is not 0.  The DOS command line buffer residue there made some disk images (other file layout) storm.  mk_page0 zeroes 16 bytes in the English build.
- The paging code: game side `secof/fixno/pg8/fixsel/page` at E9D3h-E9FBh and `newlist/cbk` at DD30h-DD55h (free in the English game: no writes in 27 save loads x 220 s);
  the key handling is DOS2 side (function 51h, `ui_srv`), `cbk` only asks for it once per menu iteration and redraws when the page changed.
- English game kernel variables: E8B1h (page table, was E8EBh), E8B9h (was E8F3h), E8BBh (was E8F5h); patch sites L1 0114h, L4 01D1h, K1 E224h, K2 E5C3h,
  M1 file13 414Bh, M2 42F8h, M3 40AFh (patches_en8.py).  No G1/G2: the English game never reads the Kanji ROM (ports D8h-DBh stay silent).
