# kittya machine (FS-A1GT with the Korean Kanji ROM)

`kittya.xml` = openMSX's stock `Panasonic_FS-A1GT.xml` with one change: the Kanji ROM is `fs-a1gt_kanjifont_ko.rom`
(the patched ROM the game needs to show Hangul; `KANJI.rom` in the repo root, md5 0ba9ee30103532dbfec34639fa2a553c,
sha1 d913f35b6855be93961627e6c26d57ff26da51a4 - openMSX finds system ROMs by sha1, so keep the `<sha1>` line in the xml).

Install (openMSX user directory: Linux `~/.openMSX`, Windows `%USERPROFILE%\Documents\openMSX`):

1. `kittya.xml`  -> `<user dir>/share/machines/kittya.xml`
2. `KANJI.rom`   -> `<user dir>/share/systemroms/fs-a1gt_kanjifont_ko.rom`
3. The stock FS-A1GT system ROMs (`fs-a1gt_firmware.rom` etc.) must already be in `share/systemroms` - they are what
   `Panasonic_FS-A1GT` uses; `kittya` reads the same files.
4. `openmsx -machine kittya -ext SunriseIDE_Nextor -command "set firmwareswitch off" -command "hda C:/path/outU.dsk"`
