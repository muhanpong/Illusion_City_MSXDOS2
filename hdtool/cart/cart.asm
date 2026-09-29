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
;     (left/right, patches P1-P6 in mkcart.py, code in uiimg).
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
DATASEC equ 128                 ; ROM offset of disk 1 sector 0, in 512-byte sectors (10000h)
SAVESEC equ 3580h               ; ROM offset of the save slots (6B0000h, 8 pairs of 64KB), mkcart.py SAVE
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
GLYPHW  equ 0E947h              ; patch G1 jumps here (E947h-E9FFh: glyph fetch + flash helpers)
GLYEND  equ 0EA00h
FONTSEC equ 3320h               ; ROM offset of the font (664000h) in 512-byte sectors (mkcart.py FONT)

        OUTPUT "cart.bin"
        ORG 4000h
        db "AB"
        dw init, 0, 0, 0, 0, 0, 0

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
        jp      0100h
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
; 0055h-0086h and 0090h-00FFh: never written by the game (the page is copied to the game's page-0
; segments at start, so this code is there whenever F37D is called). The save-slot copy lives here.
; fetch: B = position, C = chunk -> cbuf = the 32 bytes the new sector gets there (the new slot from
; RAM, the others from the current sector). Z = all FFh (nothing to program).
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
        ASSERT  $ <= 80h
        ds      80h-$,0
        db      0,0,0,98h,98h,23h,0F3h,0 ; 0080h-0087h as the original boot sector leaves them
        ds      90h-$,0
; wslot: A = slot (0-191). Copies the slot's group (24 slots) from its current flash sector into the other
; one with the new slot data, then writes the header (source generation + 1) last. NZ = flash timeout.
wslot:  call    grp
        call    invcur                  ; re-read both headers: hdrA/hdrB hold the generations
        call    curof
        ld      (wsw),a
        xor     1
        rrca
        ld      e,a
        call    pairde
        call    erase64
        ret     nz
        ld      b,0                     ; B = position 0-23, C = 32-byte chunk 0-31
.pos:   ld      c,0
.chk:   push    bc
        call    fetch
        pop     bc
        jr      z,.next
        push    bc
        ld      a,(wsw)
        xor     1
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
        ld      a,(wsw)                 ; header: 'IC' + generation + 1
        add     a,a
        add     a,a
        ld      e,a
        ld      d,0
        ld      hl,hdrA+2
        add     hl,de
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        inc     de
        ld      (cbuf+2),de
        ld      hl,'I'+'C'*256
        ld      (cbuf),hl
        ld      a,(wsw)
        xor     1
        call    hdrsec
        ld      hl,0
        ld      (soff),hl
        call    prog32
        ret     nz
        jp      invcur                  ; next access reads the headers again
        ASSERT  $ <= 100h
        ds      100h-$,0
        ENT

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
        call    wslot
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

; fmap: DE = ROM sector -> cartridge in page 2 on it, Yamanooto WREN on, HL = its address, B = 80h
fmap:   ld      a,80h
        ld      (wpg),a
        ld      h,40h
        call    curslot
        ld      (sv1),a
        ld      h,80h
        call    curslot
        ld      (sv2),a
        call    setbank
        ld      a,10h
        call    wren
        ld      b,80h
        ret
; erase64: DE = first ROM sector of a 64KB flash sector. NZ = timeout.
erase64: call   fmap
        ld      a,80h
        call    fcmd
        call    unlock
        ld      (hl),30h
        ld      c,0FFh
        jr      fdone
; prog32: DE = ROM sector, (soff) = offset -> program the 32 bytes of cbuf there, byte by byte (A0h: the
; command every flash emulation has; the MiSTer cores ignore write-buffer programming). FFh bytes are skipped
; (the sector was just erased). NZ = timeout.
prog32: call    fmap
        ld      de,(soff)
        add     hl,de
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
.ok:    jp      funmap
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
        push    de
        call    romsec
        ld      bc,512
        ld      (left),bc
        ld      bc,0
        ld      (soff),bc
.chunk: push    hl                      ; n = min(left, room to the end of the destination page)
        ld      a,h
        and     3Fh
        ld      b,a
        ld      c,l
        ld      hl,4000h
        or      a
        sbc     hl,bc
        ld      bc,(left)
        or      a
        sbc     hl,bc
        jr      nc,.all
        add     hl,bc
        ld      b,h
        ld      c,l
.all:   pop     hl
        call    xfer
        push    hl
        ld      hl,(left)
        or      a
        sbc     hl,bc
        ld      (left),hl
        ld      a,h
        or      l
        ld      hl,(soff)
        add     hl,bc
        ld      (soff),hl
        pop     hl
        jr      nz,.chunk
        pop     de
        inc     de
        pop     bc
        djnz    .sec
        xor     a
        ei
        ret

; xfer: copy BC bytes from ROM sector DE + (soff) to HL. HL advanced, BC and DE kept.
; The window is page 2, or page 1 when the destination is in page 2.
xfer:   push    de
        push    bc
        ld      a,h
        and     0C0h
        cp      80h
        ld      a,40h
        jr      z,.w
        ld      a,80h
.w:     ld      (wpg),a
        push    hl
        ld      h,40h
        call    curslot
        ld      (sv1),a
        ld      h,80h
        call    curslot
        ld      (sv2),a
        call    setbank                 ; -> HL = sector start in the window
        ld      bc,(soff)
        add     hl,bc
        pop     de
        pop     bc
        push    bc
        ldir
        push    de
        ld      a,(sv1)
        ld      h,40h
        call    enaslt
        ld      a,(sv2)
        ld      h,80h
        call    enaslt
        pop     hl
        pop     bc
        pop     de
        ret

; curslot: H = address -> A = slot id currently selected in that page. Keeps HL, DE.
curslot: ld     a,h
        rlca
        rlca
        and     3
        ld      b,a
        in      a,(0A8h)
        call    shr2b
        and     3
        ld      c,a
        push    hl
        ld      hl,EXPTBL
        add     a,l
        ld      l,a
        ld      a,(hl)
        and     80h
        jr      z,.nx
        or      c
        ld      c,a
        ld      a,l
        add     a,4
        ld      l,a
        ld      a,(hl)                  ; SLTTBL
        call    shr2b
        and     3
        add     a,a
        add     a,a
        or      c
        ld      c,a
.nx:    ld      a,c
        pop     hl
        ret
shr2b:  push    bc
        inc     b
        jr      .t
.l:     rrca
        rrca
.t:     djnz    .l
        pop     bc
        ret

; setbank: DE = ROM sector. Puts the cartridge in the window page (wpg) with the bank holding
; the sector -> HL = address of the sector in the window.
        IF MAPPER == 1
; Yamanooto: 8KB banks, bank = sector/16 = raw + 4*OFFR. OFFR (7FFEh, ENAR=01h) is only
; reachable in page 1; raw stays 0-3 so 9800h-9FFFh never turns into the SCC.
setbank: push   de
        ld      a,e
        rlca
        rlca
        and     3
        ld      b,a
        ld      a,d
        add     a,a
        add     a,a
        or      b
        ld      b,a                     ; B = OFFR = sector/64
        ld      a,e
        rrca
        rrca
        rrca
        rrca
        and     3
        ld      c,a                     ; C = raw bank
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
        jr      nz,.p2
        ld      a,c
        ld      (5000h),a
        jr      .off
.p2:    push    bc
        ld      a,(sv1)
        ld      h,40h
        call    enaslt
        ld      a,(cartsl)
        ld      h,80h
        call    enaslt
        pop     bc
        ld      a,c
        ld      (9000h),a
.off:   pop     de
        ld      a,e
        and     0Fh
        add     a,a
        ld      h,a
        ld      a,(wpg)
        add     a,h
        ld      h,a
        ld      l,0
        ret
        ELSE
; ASCII16-X: 16KB banks, 12-bit bank = address bits 8-11 + data, written anywhere in
; 6000h-6FFFh/A000h-AFFFh (4000h window) or 7000h-7FFFh/B000h-BFFFh (8000h window).
setbank: push   de
        ld      a,e
        rlca
        rlca
        rlca
        and     7
        ld      c,a
        ld      a,d
        add     a,a
        add     a,a
        add     a,a
        or      c
        ld      c,a                     ; C = bank bits 0-7
        ld      a,d
        rlca
        rlca
        rlca
        and     7
        ld      b,a                     ; B = bank bits 8-11
        push    bc
        ld      a,(wpg)
        ld      h,a
        ld      a,(cartsl)
        call    enaslt
        pop     bc
        ld      a,(wpg)
        cp      40h
        ld      a,60h
        jr      z,.w1
        ld      a,0B0h
.w1:    or      b
        ld      h,a
        ld      l,0
        ld      (hl),c
        pop     de
        ld      a,e
        and     1Fh
        add     a,a
        ld      h,a
        ld      a,(wpg)
        add     a,h
        ld      h,a
        ld      l,0
        ret
        ENDIF

; funmap: WREN off, pages 1 and 2 back. Keeps F.
funmap: push    af
        xor     a
        call    wren
        ld      a,(sv1)
        ld      h,40h
        call    enaslt
        ld      a,(sv2)
        ld      h,80h
        call    enaslt
        pop     af
        ret
; chsec: A = which (0/1), B = position, C = chunk 0-31 -> DE = ROM sector, (soff) = offset
chsec:  rrca
        ld      e,a
        ld      a,b
        call    possec
        add     a,e
        ld      e,a
        ld      a,c
        and     10h
        rrca
        rrca
        rrca
        rrca
        add     a,e
        ld      e,a
        ld      a,(tgrp)
        ld      d,a
        ld      hl,SAVESEC
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
; flget: B = position, C = chunk -> cbuf from the current sector
flget:  ld      a,(wsw)
        call    chsec
        ld      hl,cbuf
        ld      bc,32
        jp      xfer
cur:    db      1
dta:    dw      0080h
cartsl: db      0
ramsl:  db      0
wpg:    db      0
sv1:    db      0
sv2:    db      0
left:   dw      0
soff:   dw      0
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
        ld      a,(wpg)
        cp      40h
        jr      z,.p1
        ld      a,(sv1)
        ld      h,40h
        call    enaslt
.p1:    pop     bc
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
; curgp: HL = curg + tgrp
curgp:  ld      a,(tgrp)
        ld      e,a
        ld      d,0
        ld      hl,curg
        add     hl,de
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
; romsec: DE = sector of the current disk -> DE = ROM sector. Keeps BC, HL.
romsec: push    hl
        push    bc
        call    savslot
        jr      c,.lin
        call    grp
        call    curof
        rrca
        ld      e,a
        ld      a,(tpos)
        call    possec
        add     a,e
        ld      e,a
        ld      a,(thalf)
        add     a,e
        jr      .pair
.lin:   ld      a,(cur)
        ld      hl,DATASEC-1440
        ld      bc,1440
.mul:   add     hl,bc
        dec     a
        jr      nz,.mul
        add     hl,de
        ex      de,hl
        jr      .out
.pair:  ld      e,a                     ; DE = SAVESEC + tgrp*256 + E
        ld      a,(tgrp)
        ld      d,a
        ld      hl,SAVESEC
        add     hl,de
        ex      de,hl
.out:   pop     bc
        pop     hl
        ret
; curof: tgrp -> A = current sector of the pair (0/1), cached in curg
curof:  call    curgp
        ld      a,(hl)
        cp      2
        ret     c
        push    hl
        xor     a
        ld      de,hdrA
        call    rdhdr
        ld      a,1
        ld      de,hdrB
        call    rdhdr
        ld      b,0
        ld      hl,hdrB
        call    hvalid
        jr      nz,.done                ; B invalid: the first
        inc     b
        ld      hl,hdrA
        call    hvalid
        jr      nz,.done                ; only B valid
        ld      hl,(hdrB+2)
        ld      de,(hdrA+2)
        or      a
        sbc     hl,de
        jr      z,.a
        bit     7,h
        jr      z,.done                 ; B newer
.a:     ld      b,0
.done:  ld      a,b
        pop     hl
        ld      (hl),a
        ret
; invcur: forget the cached current sector of tgrp. Z.
invcur: call    curgp
        ld      (hl),0FFh
        xor     a
        ret
hvalid: ld      a,(hl)
        cp      'I'
        ret     nz
        inc     hl
        ld      a,(hl)
        cp      'C'
        ret
; rdhdr: A = which, DE = 4-byte destination
rdhdr:  push    de
        call    hdrsec
        pop     hl
        ld      bc,0
        ld      (soff),bc
        ld      bc,4
        jp      xfer
        ENT
x1len   equ     $-x1img
        ASSERT  X1BASE+x1len <= X1END

; F13Ah: buffers (no code)
x2img:
        DISP    X2BASE
cbuf:   ds      32,0FFh
hdrA:   ds      4,0
hdrB:   ds      4,0
curg:   ds      8,0FFh                  ; current sector of each group, FFh = not read yet
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
wlim:   db      0
wleft:  db      0
wsrc:   dw      0
hdrsec: rrca
        add     a,60h
        ld      e,a
; pairde: E = sector within the pair -> DE = SAVESEC + tgrp*256 + E
pairde: ld      a,(tgrp)
        ld      d,a
        ld      hl,SAVESEC
        add     hl,de
        ex      de,hl
        ret
        ENT
x3len   equ     $-x3img
        ASSERT  X3BASE+x3len <= X3END

fray:   INCBIN  "fray.dos"
FRAYLEN equ     $-fray

        ds      8000h-$,0FFh
