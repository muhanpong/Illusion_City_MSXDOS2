# icity_dsk_maker.html - browser tool that builds the .dsk

Single HTML file, no server, nothing uploaded anywhere. Drop the eight game disks (or `illucity_K.zip`), optionally a user
disk (saves), `KANJI.rom` (to use `ICITY\FONT.BIN` instead of the machine's Kanji ROM) and the DOS files
(`MSXDOS2.SYS` + `COMMAND2.COM`, or `NEXTOR.SYS`); pick the options; press *만들기*; download the `.dsk` (16MB FAT12 hard-disk image)
or a `.zip` of the same files for an SD card.

Built into the page: the launcher (`ICITY.COM`) and a boot sector only.  Everything else (game data, DOS files, font) is yours.
The page verifies the release before it patches: patched bytes and the chunk layout must match what the launcher was built for.

Files: `core.js` (port of mkdos2.py + mkhd.py, runs in browser and Node), `app.html.tpl` (UI), `assets.json` (launcher, boot sector,
patch table, expected chunk tables; regenerate with `make_assets.py`), `build_app.py` (inlines everything -> `icity_dsk_maker.html`).
Tests: `test_node.js` (image from the same inputs as the Python tool), `test_cases.js` (edge cases), `ui_test.js` (the real page in jsdom).
