# English 8-disc (MSX Translations) cartridge - tests

`python3 mkcart.py <8 English disks> <user disk.dsk> - <out>` builds `ICITY_A16X.rom` / `ICITY_YAMA.rom` (4MB each; the English release is detected from disk 1,
`-` instead of a font).  `DUMP_DATA=all9.dsk` also writes the 9 disks as the ROM serves them (the reference for the read check).
Scripts: `drive.tcl` (headless openMSX, menus by menu IX like `mkdos2/test/en8/drive.tcl`, every read checked against `IMG`, MIDI bytes, write watch), `cmp_reads.py`
(floppy `reads.log` vs cartridge `reads.log`; the floppy logs come from `mkdos2/test/en8/pair.sh`), `cpair.sh`.

## Results (2026-10-03, sjasmplus 1.24; the Korean ROMs are byte-identical to before: A16X 45d25f08..., YAMA b94f9191...)
- Boots by itself and runs the opening demo: A16X 232 of 232 reads identical to the floppy, 0 data mismatches; YAMA 222 of the first 222 (slower run), 0 mismatches.
- All 27 save slots of the four Japanese data disks (user disk built into the ROM), A16X and YAMA: 0 mismatching reads against the floppy in the compared window,
  `bad=0` (every non-save read equals the disk image), disks 2-8 entered (game disks needing banks beyond 2MB included).
- MIDI: the first 6000 non-zero MSX-MIDI bytes of the opening demo equal the floppy's (both mappers).
- Save write: slot 1 written to sector 057Ah (slot 2) returns A=00 in about 2 s and, after a restart (flash persisted), slot 2 loads exactly like slot 1;
  slot 1 written to sector 0600h (extended slot 9), page 2 of the list (right key) shows it and loading it behaves like slot 1 (86 of 86 reads), both mappers.
- Slot list paging (96 slots per disk) works (page 3 = 17-24 after two Right presses).
- Write watch (`WW=1`, 330 s MIDI opening): the game writes only 0005h-0007h, 0038h-003Ah (its interrupt vector, replacing the cartridge's `jp inth`), 0081h/0082h/0087h (its own variables),
  F323h-F324h; nothing in the cartridge's code areas.  Before that, `mkdos2/test/en8` measured every page-3 write of the engine over eight scenarios (opening, MIDI, six save loads).

## What differs from the Korean cartridge (cart.asm `IFDEF EN8`)
- The boot sector's own load: FRAY.DOS is replaced by disk 1 sectors 0Bh-12h (4096 bytes at 0100h) and the start is `PUSH 0100h / JP 0D46h`.
- The English game's boot code (0D46h) copies its code over page 0 0055h-007Ah and 0090h-00F7h, and its kernel and tables fill E000h-E96Eh, so:
  * the slot-switch helpers `subw/subr` (003Bh-) share a tail and end at 0053h (they were 27 bytes, the last `RET` at 0055h was overwritten: A8 was left on the BIOS slot
    after the first `RDSLT` and the game stalled waiting for a VDP queue);
  * the save helpers that were in page 0 (`erase64 p128 possec slotsec chsec rdhdr`) are in page 3 at EA00h (free: the engine never writes E96Fh-EDDEh);
  * the flash helpers (`unlock fcmd fwait wren allff`) are at E96Fh; there is no glyph code and no font (the English game never reads the Kanji ROM; no G1/G2);
  * ARMI is left in (the English release's extras differ).  P1-P6 (save list paging) are the same patches at the same file 9 sites.
