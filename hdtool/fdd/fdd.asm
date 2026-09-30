; fdd.asm - Illusion City floppy version without a Korean Kanji ROM: the game's glyphs come from a font on disk 1.
;
; mkfdd.py assembles this twice:
;   PART=1  loader.bin: page-3 stub (runs at E947h, copied there with the kernel image) + boot-time loader (runs in page
;           0 right after it). Both are appended to FRAY.DOS; the loader's kernel copy (0106h LD BC) grows by the stub,
;           and 0154h JP E000h becomes JP init.
;   PART=2  font1f.bin: the lookup code at 8000h of mapper segment 1Fh. mkfdd.py adds the index, block table and the
;           first compressed blocks (1Fh image) and the rest of the blocks (segment 1Eh from offset 2000h, seen at 6000h
;           when mapped in page 1); both go to disk 1 from sector FONTSEC (unused by the game, see README).
;
; Memory: the game's sector cache (file 13) is cut to end at cache index 3D0h (patches in mkfdd.py), which leaves
; segment 1Fh and 1Eh from offset 2000h free in both sound modes (MIDI: songs end at index 3C9h, 6 cache sectors).
; The end must stay above the songs: a start past the end makes file 13 take the maximum size (5A0h) instead.
; The font is 1395 glyphs (every glyph the game can print, hdtool/phase0/glyphscan) in blocks of BLK glyphs, each
; ZX0-compressed; a glyph request decompresses its block into BUF (kept while the next glyph is in the same block).
; Machines with fewer than 32 mapper segments keep using the Kanji ROM (FLAG stays 0).

        INCLUDE "fdd_def.inc"           ; mkfdd.py: PART, BLK (glyphs per block), NGLYPH, NBLK
; The font data is not assembled: mkfdd.py (and the web
; app, same rules) puts BST/LOWS/BTAB/blocks at DATA and fills in the sector numbers at n1imm/n2sec/n2imm.
FONTSEC equ     550h
DATA    equ     8140h                   ; PART 2: tables and the first blocks follow the code

E030    equ 0E030h                      ; kernel: map segment A in page B, old mapping left on the caller's stack
E033    equ 0E033h                      ; kernel: restore the mapping E030 left
BDOS    equ 0F37Dh
STUB    equ 0E947h                      ; game page 3 E947h-E9FFh: never used by the game

        IF PART == 1
; ---------------------------------------------------------------------------------------------------------------
        OUTPUT "loader.bin"
        ORG     0DA2h                   ; FRAY.DOS is loaded at 0100h and is 0CA2h long
        DISP    STUB
FLAG:   db      0                       ; 1 = font loaded
VIDX:   dw      0                       ; glyph address as the Kanji ROM ports would get it (H = D9h value, L = D8h)
VDEST:  dw      0
TEMP:   ds      32                      ; the glyph (segment 1Fh code writes it here)
; file 7 2AB9h (JP g7): HL = glyph number; 32 bytes to D500h, returns HL = D520h, BC = 00D9h as the original INIR
g7:     ld      a,(FLAG)
        or      a
        jr      z,.rom
        ld      de,0D500h
        call    fetch
        ld      hl,0D520h
        ld      bc,00D9h
        ret
.rom:   ld      a,l                     ; the three instructions the JP replaced
        add     hl,hl
        add     hl,hl
        jp      2ABCh
; file 14 (disk 1, at 8000h) ADFEh (JP g14): the same routine with its buffer at 86BCh (the ending's text)
g14:    ld      a,(FLAG)
        or      a
        jr      z,.rom
        ld      de,86BCh
        call    fetch
        ld      hl,86DCh
        ld      bc,00D9h
        ret
.rom:   ld      a,l
        add     hl,hl
        add     hl,hl
        jp      0AE01h
; HL = glyph number, DE = destination. The lookup runs from segment 1Fh in page 2; the glyph is copied after the
; original page 2 is back (file 14's buffer is in page 2).
fetch:  push    de
        ld      (VDEST),de
        ld      a,l                     ; as the original: H = (HL*4)>>8, L unchanged
        add     hl,hl
        add     hl,hl
        ld      l,a
        ld      (VIDX),hl
        ld      a,1Fh
        ld      b,2
        call    E030
        call    8000h
        call    E033
        ld      hl,TEMP
        ld      de,(VDEST)
        ld      bc,32
        ldir
        pop     de
        ret
stubend:
        ENT
STUBLEN equ     stubend-STUB
        ASSERT  STUB+STUBLEN <= 0EA00h

; boot: runs in page 0 just before the loader's JP E000h (kernel, mapper table and interrupt handler are set up)
init:   ld      a,(0E8F3h)              ; segments of the primary mapper
        cp      20h
        jr      c,igo
        ld      a,1Fh
        ld      b,2
        call    E030
        ld      de,8000h
        ld      hl,FONTSEC
n1imm:  ld      b,0                     ; sectors for segment 1Fh (mkfdd.py)
        call    rd
        call    E033
        ld      a,1Eh
        ld      b,2
        call    E030
        ld      de,0A000h               ; segment 1Eh offset 2000h
n2sec:  ld      hl,0                    ; FONTSEC + sectors for 1Fh (mkfdd.py)
n2imm:  ld      b,0                     ; sectors for segment 1Eh (mkfdd.py)
        call    rd
        call    E033
        ld      a,(ok)
        cp      2
        jr      nz,igo
        ld      a,1
        ld      (FLAG),a
igo:    jp      0E000h
; DE = DTA, HL = first sector, B = count: disk 1 (drive A), counts successful reads in ok
rd:     push    bc
        push    hl
        ld      c,1Ah
        call    BDOS
        pop     de
        pop     bc
        ld      h,b
        ld      l,0
        ld      c,2Fh
        call    BDOS
        or      a
        ret     nz
        ld      hl,ok
        inc     (hl)
        ret
ok:     db      0
        ENDIF

        IF PART == 2
; ---------------------------------------------------------------------------------------------------------------
        OUTPUT "font1f.bin"                 ; code only; mkfdd.py appends the data
        ORG     8000h
BUF     equ     0C000h-BLK*32           ; decompressed block (not on disk)
; (VIDX) -> 32 bytes at TEMP. Glyph index = (H & 7Fh)*64 + (L & 3Fh) (KANJI.rom layout): bucket = index >> 8,
; key = index & FFh; BST[bucket]..BST[bucket+1] is the bucket's slice of LOWS (sorted keys).
fontget:
        ld      hl,(VIDX)
        ld      a,l
        and     3Fh
        ld      l,a
        ld      a,h
        and     7Fh
        rrca
        rrca                            ; a = (h>>2) | (h&3)<<6
        ld      c,a
        and     0C0h
        or      l
        ld      e,a                     ; key
        ld      a,c
        and     1Fh                     ; bucket
        ld      l,a
        ld      h,0
        add     hl,hl
        ld      bc,BST
        add     hl,bc
        ld      c,(hl)
        inc     hl
        ld      b,(hl)                  ; start
        inc     hl
        ld      a,(hl)
        inc     hl
        ld      h,(hl)
        ld      l,a                     ; end
        or      a
        sbc     hl,bc
        jr      z,blank
        push    hl                      ; length
        ld      hl,LOWS
        add     hl,bc
        pop     bc
        ld      a,e
        cpir
        jr      nz,blank
        dec     hl
        ld      bc,LOWS
        or      a
        sbc     hl,bc                   ; position in the font
        ld      c,0
        ld      de,BLK
.div:   or      a
        sbc     hl,de
        jr      c,.q
        inc     c
        jr      .div
.q:     add     hl,de                   ; slot in block c
        add     hl,hl
        add     hl,hl
        add     hl,hl
        add     hl,hl
        add     hl,hl
        push    hl
        ld      a,(CUR)
        cp      c
        jr      z,.have
        ld      a,c
        ld      (CUR),a
        ld      l,c
        ld      h,0
        ld      e,l
        ld      d,h
        add     hl,hl
        add     hl,de
        ld      de,BTAB
        add     hl,de
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        inc     hl
        ld      a,(hl)
        ex      de,hl                   ; compressed block
        ld      de,BUF
        or      a
        jr      z,.dz
        ld      (SRC),hl                ; in segment 1Eh: map it in page 1 meanwhile
        ld      a,1Eh
        ld      b,1
        call    E030
        ld      hl,(SRC)
        ld      de,BUF
        call    dzx0_standard
        call    E033
        jr      .have
.dz:    call    dzx0_standard
.have:  pop     hl
        ld      de,BUF
        add     hl,de
        ld      de,TEMP
        ld      bc,32
        ldir
        ret
blank:  ld      hl,TEMP                 ; not a glyph the game prints: blank, as a missing ROM glyph
        ld      b,32
        xor     a
.z:     ld      (hl),a
        inc     hl
        djnz    .z
        ret
        INCLUDE "../cart/zx0/dzx0_standard.asm" ; ZX0 decoder by Einar Saukas & Urusergi (BSD-3, cart/zx0/LICENSE)
CUR:    db      0FFh                    ; block now in BUF
SRC:    dw      0
VIDX    equ     STUB+1                  ; PART 1 layout
TEMP    equ     STUB+5
        ASSERT  $ <= DATA
BST     equ     DATA                    ; 33 words: LOWS index where each bucket (glyph number >> 8) starts
LOWS    equ     BST+66                  ; NGLYPH bytes: glyph number & FFh, glyphs sorted
BTAB    equ     LOWS+NGLYPH             ; NBLK x (word address, byte 0 = segment 1Fh in page 2 / 1 = segment 1Eh in page 1)
BLOCKS  equ     BTAB+3*NBLK             ; ZX0 blocks: in 1Fh up to BUF, the rest in 1Eh from 6000h (offset 2000h)
        ENDIF
