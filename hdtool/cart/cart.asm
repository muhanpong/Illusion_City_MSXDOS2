; cart.asm - Illusion City (환영도시) boot-from-cartridge ROM for Yamanooto and ASCII16-X.
;
; The cartridge INIT takes over the machine and never returns: no disk ROM, no boot sector.
; It builds the state the original boot sector leaves at JP 0100 (all pages RAM, mapper 3,2,1,0,
; SP=FAF8h, 0080h-0087h) with our own interslot environment in place of the DOS1 one:
;   page 0 RAM: RDSLT 000Ch, WRSLT 0014h, CALSLT 001Ch, ENASLT 0024h, CALLF 0030h, interrupt 0038h
;   page 3 DD92h-DF7Dh (the DOS1 environment's area, HIMEM=DF7Eh): the routines behind them
;   page 3 EF80h-F139h: F37D handler, 1Ah (DTA) and 2Fh (sector read). In the original this is the
;     DOS1 disk driver's page-3 code, which runs on every sector read, so the game never writes it.
;   30h (sector write = save) and the save slots: 96 per disk (disk 1 and user disk). Slots 1-8 are the
;     game's own sectors 0578h+2n, slots 9-96 sectors 0600h+2n (patched in, beyond the disk); all live in
;     flash at 6B0000h in groups of 24 per sector pair (see x1img). The game's slot list gets pages
;     (left/right on the keyboard or a joystick, patches P1-P6 in mkcart.py, code in uiimg).
;   More code in page 3 F13Ah-F169h, F176h-F276h, F27Fh-F322h, F325h-F340h (DOS1 kernel variables the game
;     never writes, measured) and page 0 0055h-007Fh / 0090h-00FFh (never written by the game).
;   page 3 E947h-E9FFh (never touched by the game): glyph fetch + flash helpers. mkcart.py patches the
;     game's only Kanji-ROM access (file7 2AB9h, patch G1) into JP E947h; the glyph comes from the font in the ROM
;     (FONT.BIN, KANJI.rom layout), so the machine's Kanji ROM is never used.
; A sector read copies straight from the ROM: offset 10000h + ((disk-1)*1440 + sector)*512.
;
; Build: sjasmplus -DMAPPER=1 cart.asm  (1 = Yamanooto, 2 = ASCII16-X), output cart.bin (boot 16KB),
; mkcart.py appends the disk data.
        IFNDEF MAPPER
        DEFINE MAPPER 1
        ENDIF

EXPTBL  equ 0FCC1h
SLTTBL  equ 0FCC5h
RAMAD0  equ 0F341h
HIMEM   equ 0FC4Ah
BDOSJP  equ 0F37Dh
SUBREG  equ 0FFFFh
WANTDSK equ 5EC0h               ; engine: wanted disk (0-7 = 1-8, 10 = user disk), in page 1
SAVESEC equ 1A80h               ; save area 350000h: 9 flash sectors of 64KB (mkcart.py SAVE)
NSAVE   equ 9
TBLLO   equ 4000h               ; sector table (mkcart.py TBLLO/TBLHI)
TBLHI   equ 0A600h
ENVTOP  equ 0DD92h              ; interrupt stack grows down from here (as the DOS1 environment)
ENVEND  equ 0DF7Eh
RESBASE equ 0EF80h              ; see the header
RESEND  equ 0F13Ah
UIBASE  equ 0F176h              ; save-list paging (DOS1 kernel variables the game never writes)
UIEND   equ 0F277h
PAGES   equ 12                  ; 12 pages x 8 = 96 slots per disk
EXTSEC  equ 0600h               ; slot 8.. of a disk: sector EXTSEC + 2*(slot-8), beyond the 1440-sector disk
X1BASE  equ 0F27Fh              ; more of the same area (F277h and F27Eh are the game's)
X1END   equ 0F323h
X2BASE  equ 0F13Ah
X2END   equ 0F16Ah
X3BASE  equ 0F325h
X3END   equ 0F341h
        IFDEF EN8
; English 8-disc release (MSX Translations): the game's kernel and tables are E000h-E96Eh, its own code fills page 0 0055h-00F7h, and it never
; writes E96Fh-EDDEh (measured: opening demo, MIDI, 27 save loads), so the flash helpers go to E96Fh and the save helpers that were in page 0 to EA00h.
; There is no glyph code (the English game never reads the Kanji ROM) and no font in the ROM.
GLYPHW  equ 0E96Fh              ; flash helpers
GLYEND  equ 0EA00h
P0BASE  equ 0EA00h              ; erase64, p128, possec, slotsec, chsec, rdhdr (page 0 0055h-00FFh in the Korean build)
P0END   equ 0EDDFh
        ELSE
GLYPHW  equ 0E947h              ; patch G1 jumps here (E947h-E9FFh: glyph fetch + flash helpers)
GLYEND  equ 0EA00h
        ENDIF
FONTSEC equ 1880h               ; ROM offset of the font (310000h) in 512-byte sectors (mkcart.py FONT)

        OUTPUT "cart.bin"
        ORG 4000h
        db "AB"
        dw init, 0, 0, 0, 0, 0, 0
        ; 4010h-4017h (file offset 10h): the ASCII16-X file carries the signature that makes openMSX and the MiSTer
        ; core pick the ASCII16-X (flash) mapper by itself at any file size. Not in the Yamanooto file (auto would
        ; take it as ASCII16-X); 8 bytes of FFh there so that both builds keep the same code addresses.
        IF MAPPER == 2
        db "ASCII16X"
        ELSE
        ds 8,0FFh
        ENDIF

; ---------------------------------------------------------------------------------------------
; INIT: runs from page 1 of the cartridge.
init:   di
        ld      sp,ENVTOP               ; the BIOS stack (~F08Eh) is inside the resident area; we never return
        ; page 3 code first (page 3 is RAM already), then its variables
        ld      hl,envimg
        ld      de,ENVTOP
        ld      bc,envlen
        ldir
        ld      hl,resimg
        ld      de,RESBASE
        ld      bc,reslen
        ldir
        ld      hl,glyimg
        ld      de,GLYPHW
        ld      bc,glylen
        ldir
        IFDEF EN8
        ld      hl,p0img
        ld      de,P0BASE
        ld      bc,p0len
        ldir
        ENDIF
        ld      hl,uiimg
        ld      de,UIBASE
        ld      bc,uilen
        ldir
        ld      hl,x1img
        ld      de,X1BASE
        ld      bc,x1len
        ldir
        ld      hl,x2img
        ld      de,X2BASE
        ld      bc,x2len
        ldir
        ld      hl,x3img
        ld      de,X3BASE
        ld      bc,x3len
        ldir
        ; our slot (page 1)
        in      a,(0A8h)
        rrca
        rrca
        call    slotof
        ld      (cartsl),a
        ; RAM slot = slot of page 3
        in      a,(0A8h)
        rlca
        rlca
        and     3
        ld      c,a                     ; C = RAM primary
        ld      b,0
        ld      hl,EXPTBL
        add     hl,bc
        ld      a,(hl)
        and     80h
        or      c
        ld      e,a
        jr      z,.ramnx
        ld      a,(SUBREG)
        cpl
        rlca
        rlca
        and     3
        ld      d,a                     ; D = RAM secondary
        add     a,a
        add     a,a
        or      e
        ld      e,a                     ; E = RAM slot id
        ; every page of the RAM primary -> RAM secondary (page 1 stays on the cartridge,
        ; which is not behind the RAM primary)
        ld      a,d
        call    rep55
        ld      (SUBREG),a
        ld      hl,SLTTBL
        add     hl,bc
        ld      (hl),a
.ramnx: ld      a,e
        ld      (ramsl),a
        ld      hl,RAMAD0
        ld      (hl),a
        inc     hl
        ld      (hl),a
        inc     hl
        ld      (hl),a
        inc     hl
        ld      (hl),a
        ; memory mapper as the original boot leaves it
        ld      a,3
        out     (0FCh),a
        dec     a
        out     (0FDh),a
        dec     a
        out     (0FEh),a
        xor     a
        out     (0FFh),a
        ; pages 0, 2, 3 = RAM primary, page 1 = cartridge primary
        ld      a,c
        call    rep55
        and     0F3h
        ld      b,a
        ld      a,(cartsl)
        and     3
        add     a,a
        add     a,a
        or      b
        out     (0A8h),a
        ; page 0 image, FRAY.DOS at 0100h
        ld      hl,page0
        ld      de,0
        ld      bc,100h
        ldir
        ld      hl,fray
        ld      bc,FRAYLEN
        ldir
        ld      hl,ENVEND
        ld      (HIMEM),hl
        ld      a,0C3h
        ld      (BDOSJP),a
        ld      hl,bdos
        ld      (BDOSJP+1),hl
        ld      a,0C9h                  ; DOS1 kernel entries: nothing behind them
        ld      (0F368h),a
        ld      (0F36Bh),a
        ld      (0F36Eh),a
        call    scan                    ; save map (group -> flash sector, spare) from the headers
        ; leave page 1 from page 3 code
        ld      hl,golaunch
        ld      de,0C000h
        ld      bc,golen
        ldir
        ld      a,(ramsl)
        and     3
        call    rep55
        jp      0C000h

golaunch:
        DISP    0C000h
        out     (0A8h),a
        ld      sp,0FAF8h
        ei
        IFDEF EN8
        ld      hl,0100h                ; the English boot sector: PUSH 0100h, JP 0D46h (copies the loader's tables and code, then RET to 0100h)
        push    hl
        jp      0D46h
        ELSE
        jp      0100h
        ENDIF
        ENT
golen   equ     $-golaunch

; A = primary (bits 1-0) -> A = slot id of that primary's current page (secondary from SLTTBL
; for page 1 only; used for our own slot at INIT, like the usual cartridge code)
slotof: and     3
        ld      c,a
        ld      b,0
        ld      hl,EXPTBL
        add     hl,bc
        ld      a,(hl)
        and     80h
        or      c
        ld      c,a
        inc     hl
        inc     hl
        inc     hl
        inc     hl
        ld      a,(hl)
        and     0Ch
        or      c
        ret

; A = 0..3 -> A * 55h (same value in all four pages)
rep55:  ld      b,a
        add     a,a
        add     a,a
        or      b
        ld      b,a
        add     a,a
        add     a,a
        add     a,a
        add     a,a
        or      b
        ret

; ---------------------------------------------------------------------------------------------
; save-slot code that runs from this ROM bank (page 1): at INIT (scan) and through wsave (the rest)
; scan: per group the sector with a valid header and the newest generation (cbuf holds the generations
; meanwhile); the sector nobody holds is the spare
scan:   ld      hl,gsec
        ld      b,8
.c:     ld      (hl),0FFh
        inc     hl
        djnz    .c
        xor     a
.s:     ld      (tmpi),a
        call    rdhdr
        ld      hl,hbuf
        ld      a,(hl)
        cp      'I'
        jr      nz,.nx
        inc     hl
        ld      a,(hl)
        cp      'C'
        jr      nz,.nx
        inc     hl
        ld      a,(hl)
        cp      8
        jr      nc,.nx
        ld      (tgrp),a
        inc     hl
        ld      c,(hl)
        inc     hl
        ld      b,(hl)                  ; BC = generation
        call    gsecp
        ld      a,(hl)
        inc     a
        jr      z,.take
        push    hl
        ld      a,(tgrp)
        add     a,a
        add     a,LOW cbuf
        ld      l,a
        ld      h,HIGH cbuf
        ld      a,c
        sub     (hl)
        ld      e,a
        inc     hl
        ld      a,b
        sbc     a,(hl)
        pop     hl
        jp      m,.nx                   ; older
        or      e
        jr      z,.nx
.take:  ld      a,(tmpi)
        ld      (hl),a
        ld      a,(tgrp)
        add     a,a
        add     a,LOW cbuf
        ld      l,a
        ld      h,HIGH cbuf
        ld      (hl),c
        inc     hl
        ld      (hl),b
.nx:    ld      a,(tmpi)
        inc     a
        cp      NSAVE
        jr      c,.s
        ld      c,0                     ; spare = first sector no group holds
.f:     ld      hl,gsec
        ld      b,8
        ld      a,c
.g:     cp      (hl)
        jr      z,.u
        inc     hl
        djnz    .g
        ld      (spare),a
        ret
.u:     inc     c
        jr      .f
; wslot: A = slot (0-191). Copies the slot's group (24 slots) from its flash sector into the spare one with the
; new slot, then writes the header ('IC', group, generation + 1) last; the old sector becomes the spare. NZ = timeout.
wslot:  call    grp
        call    curof
        ld      (wsw),a
        ld      a,(spare)
        ld      (wdst),a
        call    p128
        ex      de,hl
        call    erase64
        ret     nz
        ld      b,0                     ; B = position 0-23, C = 32-byte chunk 0-31
.pos:   ld      c,0
.chk:   push    bc
        call    fetch
        pop     bc
        jr      z,.next
        push    bc
        ld      a,(wdst)
        call    chsec
        call    prog32
        pop     bc
        ret     nz
.next:  inc     c
        ld      a,c
        cp      32
        jr      c,.chk
        inc     b
        ld      a,b
        cp      24
        jr      c,.pos
        jp      whdr
; fetch: B = position, C = chunk -> cbuf = the 32 bytes the new sector gets there (the new slot from RAM,
; the others from the current sector). Z = all FFh (nothing to program).
fetch:  ld      a,(tpos)
        cp      b
        jr      nz,.fl
        ld      a,c
        ld      hl,wlim
        cp      (hl)
        jr      c,.ram
.fl:    call    flget
        jr      .done
.ram:   ld      l,c
        ld      h,0
        add     hl,hl
        add     hl,hl
        add     hl,hl
        add     hl,hl
        add     hl,hl
        ld      de,(wsrc)
        add     hl,de
        ld      de,cbuf
        ld      bc,32
        ldir
.done:  jp      allff
; flget: B = position, C = chunk -> cbuf from the group's current sector
flget:  ld      a,(wsw)
        call    chsec
        ld      hl,cbuf
        ld      bc,32
        jp      xfer
; whdr: the new sector's header ('IC', group, generation + 1) last, then it holds the group, the old one is spare
whdr:   ld      a,(wsw)
        call    rdhdr
        ld      hl,(hbuf+3)
        inc     hl
        ld      (cbuf+3),hl
        ld      hl,'I'+'C'*256
        ld      (cbuf),hl
        ld      a,(tgrp)
        ld      (cbuf+2),a
        ld      a,(wdst)
        call    p128
        ld      de,60h
        add     hl,de
        ex      de,hl
        ld      hl,0
        ld      (soff),hl
        call    prog32
        ret     nz
        ld      a,(wsw)
        ld      (spare),a
        call    gsecp
        ld      a,(wdst)
        ld      (hl),a
        xor     a
        ret


; ---------------------------------------------------------------------------------------------
; page 0 image
page0:
        DISP    0
        ds      0Ch,0
        jp      rdslt                   ; 000C
        ds      14h-$,0
        jp      wrslt                   ; 0014
        ds      1Ch-$,0
        jp      calslt                  ; 001C
        ds      24h-$,0
        jp      enaslt                  ; 0024
        ds      30h-$,0
        jp      callf                   ; 0030
        ds      38h-$,0
        jp      inth                    ; 0038
; secondary slot register of another primary: must run in page 0 while page 3 is switched away.
; subw: A = A8 with page 3 on the target primary, C = A8 to restore, L = keep mask, H = new bits
;       -> D = old register value, H = new register value
        IFDEF EN8
; the English game's boot code (0D46h) copies its own code to 0055h, so this has to end at 0054h: the two routines share their tail
subw:   out     (0A8h),a
        ld      a,(SUBREG)
        cpl
        ld      d,a
        and     l
        or      h
        ld      (SUBREG),a
        ld      h,a
        jr      subt
subr:   out     (0A8h),a
        ld      a,d
        ld      (SUBREG),a
subt:   ld      a,c
        out     (0A8h),a
        ret
        ASSERT  $ <= 55h
        ds      80h-$,0
        db      0,0,0,98h,98h,23h,0F3h,0 ; 0080h-0087h as the original boot sector leaves them
        ELSE
subw:   out     (0A8h),a
        ld      a,(SUBREG)
        cpl
        ld      d,a
        and     l
        or      h
        ld      (SUBREG),a
        ld      h,a
        ld      a,c
        out     (0A8h),a
        ret
; subr: A = A8 with page 3 on the target primary, C = A8 to restore, D = value to write
subr:   out     (0A8h),a
        ld      a,d
        ld      (SUBREG),a
        ld      a,c
        out     (0A8h),a
        ret
; 0055h-007Fh and 0090h-00FFh: never written by the game (the page is copied to the game's page-0 segments at
; start, so this code is there whenever F37D is called; nothing here runs while the flash window is on page 0).
; erase64: DE = first ROM sector of a 64KB flash sector. NZ = timeout.
erase64: ld     hl,0
        ld      (soff),hl
        call    fmap
        ld      a,80h
        call    fcmd
        call    unlock
        ld      (hl),30h
        ld      c,0FFh
        jp      fdone
        ASSERT  $ <= 80h
        ds      80h-$,0
        db      0,0,0,98h,98h,23h,0F3h,0 ; 0080h-0087h as the original boot sector leaves them
        ds      90h-$,0
; p128: A = flash save sector 0-8 -> HL = its first ROM sector (SAVESEC + A*128)
p128:   rrca
        ld      h,a
        and     80h
        ld      l,a
        xor     h
        ld      h,a
        ld      de,SAVESEC
        add     hl,de
        ret
; possec: A = position 0-23 -> A = its sector within the flash sector (bank*32 + (p mod 8)*2)
possec: push    bc
        ld      b,a
        and     7
        add     a,a
        ld      c,a
        ld      a,b
        and     18h
        add     a,a
        add     a,a
        add     a,c
        pop     bc
        ret
; slotsec: A = flash sector -> DE = ROM sector of slot position tpos, half thalf
slotsec: call   p128
        ld      a,(tpos)
        call    possec
        ld      e,a
        ld      a,(thalf)
        add     a,e
        ld      e,a
        ld      d,0
        add     hl,de
        ex      de,hl
        ret
; chsec: A = flash sector, B = position, C = chunk 0-31 -> DE = ROM sector, (soff)
chsec:  call    p128
        ld      a,b
        call    possec
        ld      e,a
        ld      a,c
        and     10h
        rrca
        rrca
        rrca
        rrca
        add     a,e
        ld      e,a
        ld      d,0
        add     hl,de
        ex      de,hl
        ld      a,c
        and     0Fh
        ld      l,a
        ld      h,0
        add     hl,hl
        add     hl,hl
        add     hl,hl
        add     hl,hl
        add     hl,hl
        ld      (soff),hl
        ret
; rdhdr: A = flash sector -> hbuf = its header ('I','C', group, generation)
rdhdr:  call    p128
        ld      de,60h
        add     hl,de
        ex      de,hl
        ld      hl,0
        ld      (soff),hl
        ld      hl,hbuf
        ld      bc,5
        jp      xfer
        ENDIF
        ASSERT  $ <= 100h
        ds      100h-$,0
        ENT

        IFDEF EN8
; save helpers (page 0 in the Korean build), page 3 EA00h in the English one
p0img:
        DISP    P0BASE
; erase64: DE = first ROM sector of a 64KB flash sector. NZ = timeout.
erase64: ld     hl,0
        ld      (soff),hl
        call    fmap
        ld      a,80h
        call    fcmd
        call    unlock
        ld      (hl),30h
        ld      c,0FFh
        jp      fdone
; p128: A = flash save sector 0-8 -> HL = its first ROM sector (SAVESEC + A*128)
p128:   rrca
        ld      h,a
        and     80h
        ld      l,a
        xor     h
        ld      h,a
        ld      de,SAVESEC
        add     hl,de
        ret
; possec: A = position 0-23 -> A = its sector within the flash sector (bank*32 + (p mod 8)*2)
possec: push    bc
        ld      b,a
        and     7
        add     a,a
        ld      c,a
        ld      a,b
        and     18h
        add     a,a
        add     a,a
        add     a,c
        pop     bc
        ret
; slotsec: A = flash sector -> DE = ROM sector of slot position tpos, half thalf
slotsec: call   p128
        ld      a,(tpos)
        call    possec
        ld      e,a
        ld      a,(thalf)
        add     a,e
        ld      e,a
        ld      d,0
        add     hl,de
        ex      de,hl
        ret
; chsec: A = flash sector, B = position, C = chunk 0-31 -> DE = ROM sector, (soff)
chsec:  call    p128
        ld      a,b
        call    possec
        ld      e,a
        ld      a,c
        and     10h
        rrca
        rrca
        rrca
        rrca
        add     a,e
        ld      e,a
        ld      d,0
        add     hl,de
        ex      de,hl
        ld      a,c
        and     0Fh
        ld      l,a
        ld      h,0
        add     hl,hl
        add     hl,hl
        add     hl,hl
        add     hl,hl
        add     hl,hl
        ld      (soff),hl
        ret
; rdhdr: A = flash sector -> hbuf = its header ('I','C', group, generation)
rdhdr:  call    p128
        ld      de,60h
        add     hl,de
        ex      de,hl
        ld      hl,0
        ld      (soff),hl
        ld      hl,hbuf
        ld      bc,5
        jp      xfer
        ENT
p0len   equ     $-p0img
        ASSERT  P0BASE+p0len <= P0END
        ENDIF

; ---------------------------------------------------------------------------------------------
; page 3 environment at DD92h
envimg:
        DISP    ENVTOP
; prep: A = slot id, H = address. Interrupts off.
;  -> B = A8 for the access, C = current A8, E = slot id, D = old secondary register (expanded)
;  The secondary register (and SLTTBL) of an expanded slot is already switched. HL kept.
prep:   di
        push    hl
        ld      e,a
        ld      a,h
        rlca
        rlca
        and     3
        add     a,LOW mtab
        ld      l,a
        ld      h,HIGH mtab
        ld      l,(hl)                  ; L = page mask
        ld      a,e
        and     3
        call    x55
        and     l
        ld      b,a
        in      a,(0A8h)
        ld      c,a
        ld      a,l
        cpl
        and     c
        or      b
        ld      b,a                     ; B = A8 for the access
        bit     7,e
        jr      z,.done
        ld      a,e
        rrca
        rrca
        and     3
        call    x55
        and     l
        ld      h,a                     ; H = new secondary bits
        ld      a,l
        cpl
        ld      l,a                     ; L = keep mask
        ld      a,c
        rlca
        rlca
        xor     e
        and     3
        jr      nz,.other
        ld      a,(SUBREG)              ; same primary as page 3: write directly
        cpl
        ld      d,a
        and     l
        or      h
        ld      (SUBREG),a
        ld      h,a
        jr      .tbl
.other: push    bc
        ld      a,e
        rrca
        rrca
        and     0C0h
        ld      b,a
        ld      a,c
        and     3Fh
        or      b
        pop     bc
        call    subw
.tbl:   ld      a,e
        and     3
        add     a,LOW SLTTBL
        ld      l,a
        ld      a,h
        ld      h,HIGH SLTTBL
        ld      (hl),a
.done:  pop     hl
        ret
; restsub: E = slot id, D = secondary register to put back, C = current A8. Keeps B, HL.
restsub: bit    7,e
        ret     z
        push    hl
        ld      a,e
        and     3
        add     a,LOW SLTTBL
        ld      l,a
        ld      h,HIGH SLTTBL
        ld      (hl),d
        ld      a,c
        rlca
        rlca
        xor     e
        and     3
        jr      nz,.other
        ld      a,d
        ld      (SUBREG),a
        pop     hl
        ret
.other: ld      a,e
        rrca
        rrca
        and     0C0h
        ld      l,a
        ld      a,c
        and     3Fh
        or      l
        pop     hl
        jp      subr
x55:    push    bc
        ld      b,a
        add     a,a
        add     a,a
        or      b
        ld      b,a
        add     a,a
        add     a,a
        add     a,a
        add     a,a
        or      b
        pop     bc
        ret
mtab:   db      03h,0Ch,30h,0C0h
        ASSERT  HIGH mtab == HIGH (mtab+3)

rdslt:  call    prep
        ld      a,b
        out     (0A8h),a
        ld      b,(hl)
        ld      a,c
        out     (0A8h),a
        call    restsub
        ld      a,b
        ret

wrslt:  push    de
        call    prep
        ld      a,b
        out     (0A8h),a
        ex      (sp),hl
        ld      a,l
        ex      (sp),hl
        ld      (hl),a
        ld      a,c
        out     (0A8h),a
        call    restsub
        pop     de
        ret

callf:  ex      (sp),hl
        push    af
        push    de
        ld      a,(hl)
        push    af
        pop     iy
        inc     hl
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        inc     hl
        push    de
        pop     ix
        pop     de
        pop     af
        ex      (sp),hl
calslt: exx
        ex      af,af'
        push    iy
        pop     af
        push    ix
        pop     hl
        call    prep
        push    de
        push    bc
        ld      a,b
        out     (0A8h),a
        ex      af,af'
        exx
        call    jpix
        exx
        ex      af,af'
        pop     bc
        pop     de
        di
        ld      a,c
        out     (0A8h),a
        call    restsub
        ex      af,af'
        exx
        ret
jpix:   jp      (ix)

enaslt: call    prep
        ld      a,b
        out     (0A8h),a
        ret

inth:   push    hl
        push    de
        push    bc
        push    af
        exx
        ex      af,af'
        push    hl
        push    de
        push    bc
        push    af
        push    ix
        push    iy
        ld      ix,0038h
        ld      iy,(EXPTBL-1)
        ld      hl,(savsp)
        ld      a,h
        or      l
        jr      nz,.nest
        ld      (savsp),sp
        ld      sp,ENVTOP
        call    calslt
        di
        ld      sp,(savsp)
        ld      hl,0
        ld      (savsp),hl
        jr      .out
.nest:  call    calslt
.out:   pop     iy
        pop     ix
        pop     af
        pop     bc
        pop     de
        pop     hl
        ex      af,af'
        exx
        pop     af
        pop     bc
        pop     de
        pop     hl
        ei
        ret
savsp:  dw      0

; 30h: DE = first sector, H = count, source = DTA. Only save-slot sectors are written (the game writes
; one slot: 2 sectors, even first, from F400h); anything else is ignored. A = 0 done, 1 flash timeout.
wrabs:  ld      a,h
        ld      (wleft),a
        ld      hl,(dta)
        ld      (wsrc),hl
.sec:   push    de
        call    savslot                 ; A = slot, B = half, CF = not a save sector
        jr      c,.nx
        ld      c,a
        ld      a,b
        or      a
        jr      nz,.nx                  ; odd half: written with its even partner
        ld      a,(wleft)
        cp      2
        ld      a,16
        jr      c,.half
        ld      a,32
.half:  ld      (wlim),a                ; chunks of the slot that come from RAM (16 = only the even half)
        ld      a,c
        call    wsave
        jr      nz,.err
.nx:    pop     de
        inc     de
        ld      hl,(wsrc)
        ld      bc,512
        add     hl,bc
        ld      (wsrc),hl
        ld      hl,wleft
        dec     (hl)
        jr      nz,.sec
        xor     a
        ei
        ret
.err:   pop     de
        ld      a,1
        ei
        ret

; fmap: DE = ROM sector, (soff) -> cartridge in page 2 there, Yamanooto WREN on, HL = the address, B = 80h
fmap:   ld      a,80h
        ld      (wpg),a
        in      a,(0A8h)
        ld      (sa8),a
        call    sec2b
        call    setbank
        ld      a,10h
        call    wren
        ld      b,80h
        ret
; prog32: DE = ROM sector, (soff) = offset -> program the 32 bytes of cbuf there, byte by byte (A0h: the
; command every flash emulation has; the MiSTer cores ignore write-buffer programming). FFh bytes are skipped
; (the sector was just erased). NZ = timeout.
prog32: call    fmap                    ; HL = target (soff included)
        ld      de,cbuf
        ld      a,32
.l:     push    af
        ld      a,(de)
        inc     a
        jr      z,.skip
        ld      a,0A0h
        call    fcmd                    ; keeps HL, DE
        ld      a,(de)
        ld      (hl),a
        ld      c,a
        call    fwait
        jr      nz,.fail
.skip:  inc     de
        inc     hl
        pop     af
        dec     a
        jr      nz,.l
        jr      fdone.ok                ; Z
.fail:  pop     bc
        jr      fdone.bad
fdone:  call    fwait
        jr      z,.ok
.bad:   ld      (hl),0F0h               ; reset to read mode
.ok:    push    af                      ; funmap: WREN off, pages back
        xor     a
        call    wren
        ld      a,(sa8)
        out     (0A8h),a
        pop     af
        ret
; joyrd: R15 = A, then A = R14 (joystick bits of the selected port)
joyrd:  call    wr15
        ld      a,14
        out     (0A0h),a
        in      a,(0A2h)
        ret
        ENT
envlen  equ     $-envimg
        ASSERT  ENVTOP+envlen <= ENVEND

; ---------------------------------------------------------------------------------------------
; page 3 resident part at E947h: F37D (BDOS) handler
resimg:
        DISP    RESBASE
bdos:   ld      a,c
        cp      2Fh
        jr      z,rdabs
        cp      30h
        jp      z,wrabs
        cp      1Ah
        jr      nz,.nop
        ld      (dta),de
.nop:   xor     a
        ret
; 2Fh: DE = first sector, H = count, L = drive (always A:). Sector 0 = disk identification:
; switch to the disk the engine wants first (same rule as hdtool/hook.asm).
rdabs:  ld      a,d
        or      e
        jr      nz,.go
        ld      a,(WANTDSK)
        cp      8
        jr      c,.p1
        cp      10
        jr      nz,.go
        ld      a,8
.p1:    inc     a
        ld      (cur),a
.go:    ld      b,h                     ; B = count, DE = disk sector
        ld      hl,(dta)
.sec:   push    bc
        push    hl
        push    de
        call    locate
        pop     de
        pop     hl
        push    hl
        push    de
        ex      de,hl
        call    getsec
        pop     de
        pop     hl
        inc     h
        inc     h
        inc     de
        pop     bc
        djnz    .sec
        xor     a
        ei
        ret

; locate: DE = sector of the current disk -> sbank/soffs/scnt of its data (scnt 0 = ZX0, else bytes to copy)
locate: call    savslot
        jr      c,.dat
        call    grp                     ; a save slot: raw, in the group's flash sector
        call    curof
        call    slotsec
        ld      hl,0
        ld      (soff),hl
        call    sec2b
        jr      .raw
.dat:   ld      a,(cur)
        ld      hl,-1440
        ld      bc,1440
.m:     add     hl,bc
        dec     a
        jr      nz,.m
        add     hl,de                   ; HL = table index
        push    hl
        ld      a,h                     ; low word at TBLLO + 2*index
        add     a,TBLLO/512
        ld      e,a
        ld      d,0
        ld      h,d
        add     hl,hl
        ld      (soff),hl
        ld      hl,tent
        ld      bc,2
        call    xfer
        pop     hl                      ; high byte at TBLHI + index
        ld      a,h
        srl     a
        add     a,TBLHI/512
        ld      e,a
        ld      d,0
        ld      a,h
        and     1
        ld      h,a
        ld      (soff),hl
        ld      hl,tent+2
        ld      bc,1
        call    xfer
        ld      hl,(tent)               ; bits 0-12 offset, 13 raw, 14-23 bank
        ld      a,h
        and     1Fh
        ld      h,a
        ld      (soffs),hl
        ld      a,(tent+2)
        ld      l,a
        ld      h,0
        add     hl,hl
        add     hl,hl
        ld      a,(tent+1)
        rlca
        rlca
        and     3
        or      l
        ld      l,a
        ld      (sbank),hl
        ld      a,(tent+1)
        and     20h
        ld      hl,0
        jr      z,.set
.raw:   ld      hl,512
.set:   ld      (scnt),hl
        ret

; getsec: DE = destination -> the data at sbank/soffs there (ZX0 when scnt = 0, else scnt bytes copied).
; The window is page 2, or page 1 when the destination touches page 2, or page 0 when it touches pages 1 and 2.
getsec: ld      hl,511
        add     hl,de
        ld      a,d
        and     0C0h
        ld      b,a
        ld      a,h
        and     0C0h
        ld      c,a
        ld      a,80h
        cp      b
        jr      z,.n2
        cp      c
        jr      nz,.w
.n2:    ld      a,40h
        cp      b
        jr      z,.p0
        cp      c
        jr      nz,.w
.p0:    xor     a
.w:     ld      (wpg),a
        in      a,(0A8h)
        ld      (sa8),a
        push    de
        call    setbank
        pop     de
        ld      bc,(scnt)
        ld      a,b
        or      c
        jr      z,.z
        ldir
        jr      .done
.z:     call    dzx0
.done:  ld      a,(sa8)                 ; pages back as they were (only primary slots changed)
        out     (0A8h),a
        ret

; xfer: copy BC bytes from ROM sector DE + (soff) to HL. Keeps BC, DE, HL.
xfer:   push    de
        push    bc
        push    hl
        ld      (scnt),bc
        call    sec2b
        pop     de
        push    de
        call    getsec
        pop     hl
        pop     bc
        pop     de
        ret

; sec2b: DE = ROM sector, (soff) -> sbank (8KB bank), soffs (offset in it)
sec2b:  ld      a,e
        and     0Fh
        add     a,a
        ld      h,a
        ld      l,0
        push    de
        ld      de,(soff)
        add     hl,de
        ld      (soffs),hl
        pop     hl
        ld      b,4
.s:     srl     h
        rr      l
        djnz    .s
        ld      (sbank),hl
        ret

; setbank: cartridge on the window page (wpg) with 8KB bank sbank -> HL = its byte soffs there
        IF MAPPER == 1
; Yamanooto: bank = raw + 4*OFFR, OFFR (7FFEh, ENAR = 01h) only in page 1; raw 0-3 keeps 9800h-9FFFh off the SCC.
; Window registers: 5000h (page 1), 9000h (page 2), 1000h (page 0 = mirror of 8000h-BFFFh).
setbank: ld     hl,(sbank)
        ld      a,l
        and     3
        ld      c,a
        srl     h
        rr      l
        srl     h
        rr      l
        ld      b,l
        push    bc
        ld      a,(cartsl)
        ld      h,40h
        call    enaslt
        pop     bc
        ld      a,1
        ld      (7FFFh),a
        ld      a,b
        ld      (7FFEh),a
        xor     a
        ld      (7FFFh),a
        ld      a,(wpg)
        cp      40h
        ld      a,50h
        jr      z,.reg
        push    bc
        ld      a,(sa8)
        out     (0A8h),a
        ld      a,(wpg)
        ld      h,a
        ld      a,(cartsl)
        call    enaslt
        pop     bc
        ld      a,(wpg)
        add     a,10h
.reg:   ld      h,a
        ld      l,0
        ld      (hl),c
        ld      a,(wpg)
        ld      h,a
        ld      de,(soffs)
        add     hl,de
        ret
        ELSE
; ASCII16-X: 16KB banks, 12-bit bank = address bits 8-11 + data. Registers: 6000h (page 1), B000h (page 2),
; 3000h (page 0 shows the second bank register, like page 2).
setbank: ld     hl,(sbank)
        srl     h
        rr      l
        push    hl
        ld      a,(wpg)
        ld      h,a
        ld      a,(cartsl)
        call    enaslt
        pop     bc
        ld      a,(wpg)
        rlca
        rlca
        ld      e,a
        ld      d,0
        ld      hl,a16reg
        add     hl,de
        ld      a,(hl)
        or      b
        ld      h,a
        ld      l,0
        ld      (hl),c
        ld      a,(sbank)
        and     1
        rrca
        rrca
        rrca
        ld      h,a
        ld      a,(wpg)
        add     a,h
        ld      h,a
        ld      l,0
        ld      de,(soffs)
        add     hl,de
        ret
a16reg: db      30h,60h,0B0h
        ENDIF

cur:    db      1
dta:    dw      0080h
cartsl: db      0
ramsl:  db      0
wpg:    db      0
sa8:    db      0
soff:   dw      0
sbank:  dw      0
soffs:  dw      0
scnt:   dw      0
tent:   ds      3
        ENT
reslen  equ     $-resimg
        DISPLAY "env ",/D,envlen," res ",/D,reslen
        ASSERT  RESBASE+reslen <= RESEND

; ---------------------------------------------------------------------------------------------
; page 3 E947h: glyph fetch, replaces the body of file7 2AB9h (patch G1 = JP E947h).
; In: HL = glyph code as the game gives it. Out: 32 bytes at D500h, HL=D520h, BC=00D9h like the
; original INIR; DE kept, interrupt state kept. idx = (hi&7Fh)<<6 | (lo&3Fh) (hi bit 6 = level 2),
; font offset = idx*32 = sector FONTSEC + idx/16, byte (idx&15)*32.
glyimg:
        DISP    GLYPHW
        IFNDEF EN8
glyph:  ld      a,l                     ; as the original: H = (HL*4)>>8, L unchanged
        add     hl,hl
        add     hl,hl
        ld      l,a
        ld      a,i                     ; P/V = IFF2
        push    af
        push    de
        push    hl
        ld      a,l
        and     0Fh
        ld      l,a
        ld      h,0
        add     hl,hl
        add     hl,hl
        add     hl,hl
        add     hl,hl
        add     hl,hl
        ld      (soff),hl
        pop     hl
        ld      a,l
        and     30h
        rrca
        rrca
        rrca
        rrca
        ld      e,a
        ld      a,h
        and     7Fh
        ld      l,a
        ld      h,0
        add     hl,hl
        add     hl,hl
        ld      a,l
        or      e
        ld      l,a
        ld      de,FONTSEC
        add     hl,de
        ex      de,hl
        ld      hl,0D500h
        ld      bc,32
        call    xfer
        pop     de
        pop     af
        jp      po,.di
        ei
.di:    ld      hl,0D520h
        ld      bc,00D9h
        ret

        ENDIF
; unlock: AAh -> window+AAAh, 55h -> window+555h (B = window base high byte). Keeps HL.
unlock: push    hl
        ld      a,b
        add     a,0Ah
        ld      h,a
        ld      l,0AAh
        ld      (hl),l
        ld      a,b
        add     a,05h
        ld      h,a
        ld      l,55h
        ld      (hl),l
        pop     hl
        ret
; fcmd: unlock, then A -> window+AAAh. Keeps HL.
fcmd:   push    af
        call    unlock
        pop     af
        push    hl
        ld      c,a
        ld      a,b
        add     a,0Ah
        ld      h,a
        ld      l,0AAh
        ld      (hl),c
        pop     hl
        ret
; fwait: until (HL) = C. Z = done, NZ = timeout (several seconds).
fwait:  push    de
        ld      de,0
        ld      a,40h
        ld      (tmo),a
.l:     ld      a,(hl)
        cp      c
        jr      z,.ok
        dec     de
        ld      a,d
        or      e
        jr      nz,.l
        ld      a,(tmo)
        dec     a
        ld      (tmo),a
        jr      nz,.l
        or      1
.ok:    pop     de
        ret
; wren: A = ENAR value (Yamanooto only; 7FFFh is reachable in page 1 only). Keeps HL, DE, B.
wren:
        IF MAPPER == 1
        push    hl
        push    de
        push    bc
        push    af
        ld      a,(cartsl)
        ld      h,40h
        call    enaslt
        pop     af
        ld      (7FFFh),a
        in      a,(0A8h)                ; page 1 back as it was
        and     0F3h
        ld      b,a
        ld      a,(sa8)
        and     0Ch
        or      b
        out     (0A8h),a
        pop     bc
        pop     de
        pop     hl
        ENDIF
        ret
tmo:    db      0
; allff: Z = cbuf is all FFh
allff:  ld      hl,cbuf
        ld      b,32
        ld      a,0FFh
.l:     and     (hl)
        inc     hl
        djnz    .l
        inc     a
        ret
        ENT
glylen  equ     $-glyimg
        ASSERT  GLYPHW+glylen <= GLYEND

; ---------------------------------------------------------------------------------------------
; page 3 F176h: save-list paging. The game's slot list (file9 58C0h) shows 8 slots; patches P1-P6
; (mkcart.py) make it show page*8+1 .. page*8+8, left/right switching pages on the disk media.
uiimg:
        DISP    UIBASE
; P1 (590Ah LD HL,0 -> LD HL,cbk): the menu loop (file7 308Ah) calls this with A = current item.
cbk:    ld      a,(5EC3h)               ; medium: 1 Quick, 2 SRAM, 3 disk 1, 4 user disk
        cp      3
        ret     c
        in      a,(0AAh)                ; keyboard row 8: bit 4 left, bit 7 right (0 = pressed)
        ld      e,a
        and     0F0h
        or      8
        di
        out     (0AAh),a
        in      a,(0A9h)
        ld      d,a
        ld      a,e
        out     (0AAh),a
        ei
        ld      a,d
        cpl
        ld      b,a
        call    joy                     ; + joystick left/right (a gamepad on MiSTer)
        bit     5,a
        jr      z,1F
        or      80h                     ; right as on the keyboard
1:      or      b
        and     90h
        ld      b,a
        ld      a,(pkey)
        cpl
        and     b                       ; newly pressed
        ld      c,a
        ld      a,b
        ld      (pkey),a
        ld      a,(page)
        bit     4,c
        jr      nz,.left
        bit     7,c
        ret     z
        inc     a
        cp      PAGES
        ret     nc
        jr      .set
.left:  or      a
        ret     z
        dec     a
.set:   ld      (page),a
        call    5944h                   ; rebuild the 8 rows
        xor     a
        ld      (34D3h),a               ; no highlight drawn any more
        ld      iy,5BC0h
        ld      ix,5C86h
        ld      a,(34D2h)
        jp      320Ch                   ; draw the highlight on the current item
; P2 (5957h LD (D56Ah),A): slot number shown = page*8 + row; A (row) kept
fixno:  push    af
        push    bc
        ld      b,a
        call    pg8
        ld      (0D56Ah),a
        pop     bc
        pop     af
        ret
; P3 (5910h LD (5EC5h),A): selected slot = page*8 + row
fixsel: push    bc
        ld      b,a
        call    pg8
        ld      (5EC5h),a
        ld      a,b
        pop     bc
        ret
pg8:    ld      a,(page)                ; A = page*8 + B
        add     a,a
        add     a,a
        add     a,a
        add     a,b
        ret
; P4 (58E3h CALL 5944h): opening the list; SRAM (8 slots) always starts on page 0
newlist: ld     a,(5EC3h)
        cp      3
        jr      nc,.keep
        xor     a
        ld      (page),a
.keep:  jp      5944h
; P5/P6 (5A66h/5A8Fh LD HL,0578h / ADD HL,DE / ADD HL,DE): sector of slot E (D = 0)
secof:  ld      a,e
        cp      8
        jr      nc,.ext
        ld      hl,0578h
        add     hl,de
        add     hl,de
        ret
.ext:   sub     8
        ld      l,a
        ld      h,0
        add     hl,hl
        ld      de,EXTSEC
        add     hl,de
        ret

; savslot: DE = sector of the current disk -> A = save slot 0-191 (user disk +96), B = half (sector & 1),
; CF = not a save sector. Slots 0-7: 0578h + 2n, slots 8-95: EXTSEC + 2(n-8). Keeps DE.
savslot: ld     a,(cur)
        cp      1
        jr      z,.d
        cp      9
        jr      nz,.no
.d:     ld      hl,-EXTSEC
        add     hl,de
        jr      c,.ext
        ld      hl,-578h
        add     hl,de
        jr      nc,.no
        ld      a,h
        or      a
        jr      nz,.no
        ld      a,l
        cp      10h
        jr      nc,.no
        jr      .got
.ext:   ld      a,h
        or      a
        jr      nz,.no
        ld      a,l
        cp      (PAGES-1)*16
        jr      nc,.no
        add     a,10h
.got:   ld      b,a
        and     1
        ld      c,a
        ld      a,b
        srl     a
        ld      b,c
        ld      c,a
        ld      a,(cur)
        cp      9
        ld      a,c
        jr      nz,.ok
        add     a,PAGES*8
.ok:    or      a                       ; CF = 0: a save sector
        ret
.no:    scf
        ret
; grp: A = slot -> tgrp = slot / 24, tpos = slot mod 24, thalf = B
grp:    ld      c,0
.l:     cp      24
        jr      c,.d
        sub     24
        inc     c
        jr      .l
.d:     ld      (tpos),a
        ld      a,c
        ld      (tgrp),a
        ld      a,b
        ld      (thalf),a
        ret
page:   db      0
pkey:   db      0
        ENT
uilen   equ     $-uiimg
        ASSERT  UIBASE+uilen <= UIEND

; ---------------------------------------------------------------------------------------------
; page 3 F27Fh: save slots in flash. Group g (24 slots) = flash sector pair SAVESEC + g*256 (+128 for
; the second); slot position p lives in the first 8KB of 16KB bank p/8 at (p mod 8)*1KB (ASCII16-X
; changes a bank register when written in the second 8KB of a bank); the header 'IC' + generation (16 bit)
; is at bank 3 (+60h sectors). The sector with the valid, newer header is current.
x1img:
        DISP    X1BASE
; gsecp: HL = gsec + tgrp
gsecp:  ld      a,(tgrp)
        ld      e,a
        ld      d,0
        ld      hl,gsec
        add     hl,de
        ret
; curof: tgrp -> A = flash sector (0-8) of the group (the map is read at start, see scan)
curof:  call    gsecp
        ld      a,(hl)
        ret
; wsave: A = slot -> wslot, which runs from the cartridge ROM in page 1 (its first 16KB: the boot banks)
; while the flash window is page 2 and the data page 3. NZ = flash timeout.
wsave:  ld      c,a
        in      a,(0A8h)
        push    af
        push    bc
        ld      a,(cartsl)
        ld      h,40h
        call    enaslt
        IF MAPPER == 1
        ld      a,1                     ; OFFR = 0, then region 0/1 = banks 0/1
        ld      (7FFFh),a
        xor     a
        ld      (7FFEh),a
        ld      (7FFFh),a
        ld      (5000h),a
        inc     a
        ld      (7000h),a
        ELSE
        xor     a
        ld      (6000h),a
        ENDIF
        pop     bc
        ld      a,c
        call    wslot
        pop     bc
        ld      a,b
        out     (0A8h),a
        ret
; joy: A = joystick port 1 or 2 left -> bit 4, right -> bit 5 (1 = pressed); PSG R15 kept
joy:    di
        ld      a,15
        out     (0A0h),a
        in      a,(0A2h)
        ld      e,a
        and     0BFh                    ; R15 bit 6 = 0: port 1
        call    joyrd
        ld      d,a
        ld      a,e
        or      40h                     ; port 2
        call    joyrd
        and     d                       ; 0 = pressed on either port
        ld      d,a
        ld      a,e
        call    wr15
        ei
        ld      a,d
        cpl
        and     0Ch                     ; bit 2 left, bit 3 right
        rlca
        rlca                            ; left -> bit 4, right -> bit 5
        ret
dzx0:
        INCLUDE "zx0/dzx0_standard.asm"   ; ZX0 decoder by Einar Saukas & Urusergi (BSD-3, zx0/LICENSE)
        ENT
x1len   equ     $-x1img
        ASSERT  X1BASE+x1len <= X1END

; F13Ah: buffers (no code)
x2img:
        DISP    X2BASE
cbuf:   ds      32,0FFh
hbuf:   ds      5,0
gsec:   ds      8,0FFh                  ; flash sector of each group
spare:  db      0FFh                    ; the free flash sector; FFh = map not read yet
        ENT
x2len   equ     $-x2img
        ASSERT  X2BASE+x2len <= X2END

; F325h / F345h: small code and variables
x3img:
        DISP    X3BASE
tgrp:   db      0
tpos:   db      0
thalf:  db      0
wsw:    db      0
wdst:   db      0
wlim:   db      0
wleft:  db      0
wsrc:   dw      0
tmpi:   db      0
wr15:   push    af                      ; PSG R15 = A
        ld      a,15
        out     (0A0h),a
        pop     af
        out     (0A1h),a
        ret
        ENT
x3len   equ     $-x3img
        ASSERT  X3BASE+x3len <= X3END

fray:   INCBIN  "fray.dos"
FRAYLEN equ     $-fray

        ds      8000h-$,0FFh
