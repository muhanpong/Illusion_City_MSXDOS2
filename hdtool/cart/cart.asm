; cart.asm - Illusion City (환영도시) boot-from-cartridge ROM for Yamanooto and ASCII16-X.
;
; The cartridge INIT takes over the machine and never returns: no disk ROM, no boot sector.
; It builds the state the original boot sector leaves at JP 0100 (all pages RAM, mapper 3,2,1,0,
; SP=FAF8h, 0080h-0087h) with our own interslot environment in place of the DOS1 one:
;   page 0 RAM: RDSLT 000Ch, WRSLT 0014h, CALSLT 001Ch, ENASLT 0024h, CALLF 0030h, interrupt 0038h
;   page 3 DD92h-DF7Dh (the DOS1 environment's area, HIMEM=DF7Eh): the routines behind them
;   page 3 EF80h-F139h: F37D handler, 1Ah (DTA) and 2Fh (sector read). In the original this is the
;     DOS1 disk driver's page-3 code, which runs on every sector read, so the game never writes it.
;   30h (sector write = save): the save slots (disk 1 / user disk 0578h-0587h) are redirected to
;     16 flash sectors of 64KB at 6B0000h; a write erases the slot's flash sector and programs it.
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
SAVESEC equ 3580h               ; ROM offset of the save slots (6B0000h, 16 x 64KB), mkcart.py SAVE
ENVTOP  equ 0DD92h              ; interrupt stack grows down from here (as the DOS1 environment)
ENVEND  equ 0DF7Eh
RESBASE equ 0EF80h              ; see the header
RESEND  equ 0F13Ah
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
        ds      80h-$,0
        db      0,0,0,98h,98h,23h,0F3h,0 ; 0080h-0087h as the original boot sector leaves them
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
; one slot: 2 sectors at 0578h+2n from F400h); anything else is ignored. A = 0 done, 1 flash timeout.
wrabs:  ld      b,h
        ld      hl,(dta)
.sec:   push    bc
        push    de
        push    hl
        call    romsec
        ld      a,d
        cp      HIGH SAVESEC
        jr      c,.skip
        call    flashsec
        jr      nz,.err
.skip:  pop     hl
        ld      bc,512
        add     hl,bc
        pop     de
        inc     de
        pop     bc
        djnz    .sec
        xor     a
        ei
        ret
.err:   pop     hl
        pop     de
        pop     bc
        ld      a,1
        ei
        ret

; flashsec: DE = ROM sector (first 8KB of a 64KB flash sector), HL = 512 bytes of RAM.
; Even sector: erase the 64KB flash sector first. Z = done, NZ = timeout.
flashsec:
        ld      a,e
        and     1
        ld      (fpar),a
        push    hl
        ld      a,h                     ; window page: 2, or 1 when the data is in page 2
        and     0C0h
        cp      80h
        ld      a,40h
        jr      z,.w
        ld      a,80h
.w:     ld      (wpg),a
        ld      h,40h
        call    curslot
        ld      (sv1),a
        ld      h,80h
        call    curslot
        ld      (sv2),a
        call    setbank                 ; HL = target in the window
        ld      a,10h                   ; Yamanooto: ENAR = WREN
        call    wren
        pop     de                      ; DE = source
        ld      a,(wpg)
        ld      b,a                     ; B = window base (command addresses)
        ld      a,(fpar)
        or      a
        jr      nz,.prog
        ld      a,80h
        call    fcmd
        call    unlock
        ld      (hl),30h
        ld      c,0FFh
        call    fwait
        jr      nz,.done
.prog:  ld      a,0A0h
        call    fcmd
        ld      a,(de)
        ld      (hl),a
        ld      c,a
        call    fwait
        jr      nz,.done
        inc     de
        inc     hl
        ld      a,l
        or      a
        jr      nz,.prog
        bit     0,h
        jr      nz,.prog                ; 512 bytes (target is 512-aligned)
.done:  push    af
        jr      z,.ok
        ld      (hl),0F0h               ; reset to read mode
.ok:    xor     a
        call    wren
        ld      a,(sv1)
        ld      h,40h
        call    enaslt
        ld      a,(sv2)
        ld      h,80h
        call    enaslt
        pop     af
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

; romsec: DE = sector of the current disk -> DE = ROM sector. Keeps BC, HL.
; Save slots (disk 1 and user disk, 0578h-0587h, 2 sectors each) live in their own 64KB flash sectors:
; ROM sector SAVESEC + slot*128 + (sector&1), slot = user*8 + (sector-0578h)/2.
romsec: push    hl
        push    bc
        ld      a,(cur)
        cp      1
        jr      z,.sv
        cp      9
        jr      nz,.lin
.sv:    ld      hl,-578h
        add     hl,de
        jr      nc,.lin
        ld      a,h
        or      a
        jr      nz,.lin
        ld      a,l
        cp      10h
        jr      nc,.lin
        ld      a,(cur)
        cp      9
        ld      a,l
        jr      nz,.d1
        add     a,10h
.d1:    ld      c,a
        and     1Eh
        ld      l,a
        ld      h,0
        add     hl,hl
        add     hl,hl
        add     hl,hl
        add     hl,hl
        add     hl,hl
        add     hl,hl
        ld      a,c
        and     1
        or      l
        ld      l,a
        ld      de,SAVESEC
        jr      .add
.lin:   ld      a,(cur)
        ld      hl,DATASEC-1440
        ld      bc,1440
.mul:   add     hl,bc
        dec     a
        jr      nz,.mul
.add:   add     hl,de
        ex      de,hl
        pop     bc
        pop     hl
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
fpar:   db      0
tmo:    db      0
        ENT
glylen  equ     $-glyimg
        ASSERT  GLYPHW+glylen <= GLYEND

fray:   INCBIN  "fray.dos"
FRAYLEN equ     $-fray

        ds      8000h-$,0FFh
