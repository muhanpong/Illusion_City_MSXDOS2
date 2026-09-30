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
