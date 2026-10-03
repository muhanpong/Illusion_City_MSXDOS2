ILLUSION CITY (English) - MSX-DOS2 hard disk version
====================================================

English translation: MSX Translations (the 8-disc release, "Illusion City (1991)(Micro Cabin)(en)(Disk n of 8)[MSX Translations]").
This package only repackages the game so that it runs from a hard disk / SD card under MSX-DOS2 or Nextor; all credit for the
translation goes to MSX Translations.

What you need
  - MSX turbo R (FS-A1GT) with 512KB, and a storage device that boots MSX-DOS2 (the built-in ASCII DOS2 or Nextor): SD / CF / IDE
  - about 10MB of free space.  No Kanji ROM is needed (the English game does not use it).

Install
  1. Copy ICITY.COM and the ICITY folder from this folder to the root of the storage device:
       X:\ICITY.COM
       X:\ICITY\D1 ... D8, DU, SAVE
  2. Boot into DOS2 and run ICITY from that drive:
       A:\> ICITY

What you see
  - The first lines show the number of free mapper segments and the mode:
      mode segments: 13 MIDI+FM   -> the game starts with its sound menu (FM / MIDI); needs 19 free segments or more
      mode segments: 10 FM only   -> the game starts with FM sound (16 to 18 free segments)
  - Fewer than 16 free segments: "not enough free mapper segments", the program ends.  Please report the number shown.
  - Game menu: load a save point / watch the opening demo / start from the beginning.  There is no disk-swap prompt: ICITY gives the
    game each disk it asks for.

Saves
  - 96 save slots on "Game Disk 1" and 96 on the "User Disk" (12 pages of 8).  In the save / load slot list press Left / Right (or joystick 1
    left / right) to turn the page (slot numbers 9, 10 ... 96).  Redrawing a page takes a few seconds (the game's own text speed).
    SRAM and Quick work as before.
    They are stored in \ICITY\SAVE\D1_0578.DAT and \ICITY\SAVE\DU_0578.DAT (96KB each).
    Do not delete these two files, and copy them along when you back up.
  - The user disk image given to the build is the starting content of the user disk saves (a blank, all-zero disk image gives empty slots;
    a Japanese "Data Disk" image gives that disk's saves).

If something goes wrong
  - "DOS error xx (fn sec cnt addr file)": please report the whole line.
  - If it stops before the lines above appear, check that you booted MSX-DOS2 (an A:\> or A> prompt).
  - Many small files make a slow directory: build with MERGE=16 for fewer pieces.

Files in this folder
  ICITY.COM        the launcher (builds the game's memory environment on DOS2 and serves its disk reads)
  ICITY\Dn\        disk n cut into files (file name = start sector)
  ICITY\DU\        the user disk
  ICITY\SAVE\      the save slot files
  SHA1SUMS.txt     SHA-1 of every file (to check a damaged copy)
