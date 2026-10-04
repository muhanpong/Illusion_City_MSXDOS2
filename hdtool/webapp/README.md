# icity_dsk_maker.html - browser tool that builds the hard-disk image (.hd.dsk), the cartridge ROMs or the floppy version

Single HTML file, no server, nothing uploaded anywhere. Drop the eight game disks (or `illucity_K.zip`), optionally a user
disk (saves), `KANJI.rom` (to use `ICITY\FONT.BIN` instead of the machine's Kanji ROM) and the DOS files
(`MSXDOS2.SYS` + `COMMAND2.COM`, or `NEXTOR.SYS`); pick the options; press *만들기*; download the `.hd.dsk` (16MB FAT12 hard-disk image, a raw sector image: openMSX `hda`, or rename to `.vhd` for MiSTer)
or a `.zip` of the same files for an SD card.

*만들 것 = 카트리지 ROM*: the same disks (+ user disk) and `KANJI.rom` (required) give the two cartridge ROMs of `hdtool/cart`
(4MB each: `ICITY_YAMA.rom` for Yamanooto, `ICITY_A16X.rom` for ASCII16-X), byte-identical to `hdtool/cart/mkcart.py`
(core.js has a byte-identical port of the ZX0 v2.2 compressor the cartridge data uses).
The page carries only the cartridge's 16KB boot block per mapper; FRAY.DOS is taken from the given disk 1.

*만들 것 = 플로피*: the eight disks and `KANJI.rom` (required) give the floppy version of `hdtool/fdd` (disk 1 patched so the game
reads its glyphs from a font on the disk: no Korean Kanji ROM needed), byte-identical to `hdtool/fdd/mkfdd.py`. Downloads: `D1.dsk`
alone, or the eight disks as a zip. The page carries the assembled FRAY.DOS tail, the segment-1Fh code and the glyph list
(`make_fdd_assets.py`; rerun it and `build_app.py` whenever `hdtool/fdd` changes). Test: `test_fdd.js` (disk 1 equal to mkfdd.py + edge cases).

Built into the page: the launcher (`ICITY.COM`) and a boot sector only.  Everything else (game data, DOS files, font) is yours.
The page verifies the release before it patches: patched bytes and the chunk layout must match what the launcher was built for.

Files: `core.js` (port of mkdos2.py + mkhd.py, runs in browser and Node), `app.html.tpl` (UI), `assets.json` (launcher, boot sector,
patch table, expected chunk tables; regenerate with `make_assets.py`; its `cart` part with `make_cart_assets.py`, no game data
needed - rerun it and `build_app.py` whenever `hdtool/cart/cart.asm` or `mkcart.py` changes), `build_app.py` (inlines everything -> `icity_dsk_maker.html`).
Tests: `test_node.js` (image from the same inputs as the Python tool), `test_cases.js` (edge cases), `ui_test.js` (the real page in jsdom; `cart` as last argument for the ROM mode),
`test_cart.js` (ROMs equal to mkcart.py output + edge cases).

## English 8-disc release (MSX Translations)
`core.js` recognises the release from disk 1's boot sector (`ICITY.isEn8`, `cls.release === 'en8'`; disks are still identified by the IPROJ0n label) and then uses
`assets.en8` (launcher assembled with `-DEN8`, patch table of `mkdos2/patches_en8.py`, expected chunk tables, `DIST_README_EN8.txt`) for the DOS2 build and
`assets.cartEn8` (boot blocks of `cart.asm -DEN8`, FRAY slot of 4096 bytes = disk 1 sectors 0Bh-12h, patches P1-P6) for the ROMs.  No font, no KANJI.rom, no floppy
(`buildFdd` refuses); `chunkStarts(img, tag, en8)` reads the loader's file table / the INF at sector 14; `saveSlots` shows the scene code only (the English place names
are dictionary-compressed text).  Generate with `SJASM=<sjasmplus> python3 make_en8_assets.py <dir: eight English .dsk + a user disk>` (adds the two keys to assets.json,
the Korean ones are untouched), then `build_app.py`.  Test: `node test_en8.js <English disk dir> <user disk> <mkdos2.py out tree> <ICITY.COM -DEN8 for that tree> <mkcart.py out dir>`
(every chunk/save file, the launcher and both ROMs must equal the Python tools; edge cases); `ui_test.js` takes a directory and `-` for the English release.

## Language tabs and the Japanese original (2026-10-03)
The page has three tabs at the top — Korean, English, Japanese (labels in the language shown, the hover tooltip of each tab in its own language; the choice is remembered in localStorage).
A tab sets the page language and the release its intro talks about; the build itself always follows the release found on the disks
(`classify` → `cls.release`: `ko`, `ja`, `en8`, or `en6` = the 6-disk English translation, refused). If the disks belong to another tab,
a note offers to switch. Download names: `ICITY*` (Korean), `ICITY_EN*`, `ICITY_JA*`.
Japanese original: same layout and patch sites as the Korean release, told apart by its text (`isJa`: Shift-JIS kana in disk 1 file 10);
`saveSlots` decodes its place names as Shift-JIS. DOS2 and cartridge builds use the Korean path; the font is optional for both: the
standard (Japanese) Kanji ROM is what the game was made for, so without a font file nothing is patched and the game reads the machine's
Kanji ROM through its own routines (the cartridge then takes the English release's no-font path: no G1/G2, font area FFh). A 256KB
Kanji ROM dump, if added, becomes FONT.BIN (DOS2) or the cartridge font (G1/G2, as in the Korean release). No floppy version.
Checked on a standard GT: cartridge without font (reads 125/125 from the start point and 114/114 after loading a Data Disk 3 save,
only the save-list patch site differs; ending intro text through the machine's Kanji ROM), cartridge with font (only the G1/P sites
differ) and the DOS2 image (Nextor, boots to the Japanese menus). The Japanese "Data Disk 1-4" are user disks with saves (27 slots, levels 1-36); they also load in
the Korean and English releases.
`make_en8_assets.py` uses the English mkdos2/cart sources on this branch (merged from `illuk_EN`).

## ASCII16-X file size (2026-10-04)
In the cartridge mode a choice "ASCII16-X file size" offers 4MB (default) or 8MB. The MiSTer core takes the 4MB file as flash by its
"ASCII16X" signature when the OSD mapper is on auto; with the OSD mapper set to ASCII16X by hand it takes a file as flash only when it is
larger than 4MB (`memory_upload.sv`, `rom_big`), so the 8MB file is the same ROM padded with FFh. `buildCart({pad8: true})` adds the
entry `A16X_8MB`; the page always builds it and the choice only picks the download (`*_A16X_8MB.rom`). Same as `mkcart.py --pad8`.
Checked: page = mkcart.py byte for byte (Korean), first 4MB = the 4MB file and the rest FFh (Korean, English, Japanese), the 8MB file
runs in openMSX (`-romtype ASCII16-X`, start point, 125 reads, only the patch sites differ).

## Python ↔ page equivalence for every release (2026-10-04)
The command-line tools of this branch know all three releases, with the same detection as `core.js` (`is_en8`, `is_en6` refused,
`is_ja` by the kana count): `mkdos2.py` (+ `icity.asm -DEN8` for English), `mkcart.py [--pad8] <disks> <user> <font|->`
(`-` = no font: English always, Japanese optional, Korean refused). `test_cli.sh <work> <English disks> <Japanese disks> <user disk>
<Japanese Kanji ROM>` builds the references with them and runs `test_en8.js` (English) and `test_ja.js` (Japanese without and with a
font file): every chunk/save file, ICITY.COM and the 4MB/8MB ROMs byte-identical. Korean: `test_node.js`, `test_cart.js`, `test_fdd.js`.

## Several user disks (2026-10-04)
Up to 12 user disks: user disk k fills page k of the 96-slot user-disk save list (its 8 slots, sectors 0578h-0587h, become slots
8k-7..8k), in the DOS2 save file `ICITY\SAVE\DU_0578.DAT` (offset (k-1)*8KB) and in the cartridge flash. The game only ever reads a
user disk's sector 0 and its slots, so nothing else is needed: in the game, the page of the slot list (left/right) picks the user
disk. The page takes the extra 720KB disks that are not game disks as user disks in file-name order (`cls.users`, `cls.user` = the
first); `mkdos2.py --user DISK` / `mkcart.py --user DISK` (repeatable) add pages 2, 3, ... after the usual user disk.
Checked: page = Python for 5 user disks (test_cli.sh), and in openMSX a cartridge with 5 user disks loads page 3 slot 4 (slot 20,
sector 0616h) and enters disk 5 as that save says.

## Slot-list page change: leftover text (2026-10-04)
The game draws each slot-list row into a buffer at (0,240) and copies only the text's width to (20, 52+12k) on pages 0 and 1, so
after a page change a shorter name left the end of the previous page's longer one (easy to see with Japanese place names). Before
the redraw the launchers / cartridge now fill x 20-253, y 52-147 of both pages with the window's background (read at x 252, y 52)
and wait for the fill to end (the game's next glyph, an HMMC, does not wait for the command unit and would cut it short).
DOS2 Korean/Japanese: `cbk` jumps to `clrgo` (5 free bytes at E95Bh) = function 52h, `clr_srv` clears and returns into 5944h by
putting it under the hook's saved AF on the game stack (no file-9 patch address moves). DOS2 English: `ui_srv` clears when the page
changes. Cartridge: `cbk` calls `vclr` in the boot ROM through `romix` (the former `wsave` path; `grp` moved to the resident part).
Checked in openMSX: Japanese DOS2 and cartridge, English DOS2 and cartridge, page right/right/left with no leftovers (VRAM dumps);
Korean cartridge save test 16/16 on both mappers and 125 reads (only the patch sites differ). Korean outputs change (launcher, cartridge).
