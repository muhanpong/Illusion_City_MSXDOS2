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
The page has three tabs at the top — Korean, English, Japanese (labels in the language shown; the choice is remembered in localStorage).
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
`make_en8_assets.py` needs the English mkdos2/cart sources of branch `illuk_EN`; the generated keys are already in `assets.json` here.
