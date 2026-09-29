; ICITY.COM - Illusion City launcher for MSX-DOS2 / Nextor (PLAN_BINPATCH.md)
;
; Two environments share the machine: DOS2 (pages 03/02/01/00) and the game, which lives in
; mapper segments allocated here.  The game's F37D BDOS entry is routed to a stub at 0090h that
; exists identically in every page-0 segment; it switches to the DOS2 environment, where
; dos2_service maps the game's destination segment into page 2 and reads the chunk files.
;
; build: sjasmplus icity.asm  (needs chunks.inc from mkdos2.py in the include path)
        OUTPUT "ICITY.COM"
        DEFINE N_MIDI   19              ; logical segments for MIDI+FM mode (00-12h: module, player, song reader)
        DEFINE N_FM     16              ; logical segments for FM-only mode (E8F5=10h: the MIDI module is not loaded)
        ; -DFORCE_FM=1 makes the launcher pick FM-only mode even when enough segments are free (testing)
        DEFINE TBL      0E960h          ; logical->physical table in game page 3 (patch K1 reads it)
        DEFINE INIT_N   0DB6h           ; LD A,N immediate inside init_map (patches.py INIT_MAP_N)
        DEFINE GSP      0E948h          ; game-side vars in game page 3 (E947-E95F unused by game)
        DEFINE DTA      0E94Ah
        DEFINE RSEC     0E94Ch
        DEFINE RHL      0E94Eh
        DEFINE RFN      0E950h
        DEFINE PH_FC    0080h           ; DOS2-side page 0 vars: physical segment per page at entry
        DEFINE PH_FD    0081h
        DEFINE PH_FE    0082h
        DEFINE PH_FF    0083h
        DEFINE RES      0084h           ; result for the game (A)
        DEFINE WIN      8000h           ; DOS2 page 2 window
        DEFINE GLYPHW   0E980h          ; glyph wrapper in game page 3 (E947-E9FF unused by the game)
        DEFINE GBUF_D500 0D500h         ; the game's glyph buffer
        DEFINE BDOS     0005h
        DEFINE EXTBIO   0FFCAh
        DEFINE GAME_SP  0F300h          ; loader stack until the kernel sets FAF8h
        DEFINE dos_stack 0D700h         ; DOS2-side stack: page 3 TPA. The kernel swaps page 0 (segment 1Ah) and page 1 (ROM) during calls,
                                        ; so stack, code and parameter buffers all live in page 3 (C000-D5FF); page 2 is the window
        DEFINE FRAY_SEC 14
        DEFINE FRAY_CNT 7
        DEFINE SAVE_SEC 0578h

; ---------------------------------------------------------------- .COM header: move body to C000h
        ORG 0100h
        ld      hl,body_img
        ld      de,0C000h
        ld      bc,img_end-body_img
        ldir
        jp      body
STUB_R  equ 0C000h+(stub_img-body_img)  ; relocated address of the stub image
body_img:
        DISP 0C000h
body:
        ld      sp,dos_stack
        ld      de,s_banner
        call    prs
        ; --- DOS2?
        ld      c,6Fh
        call    BDOS
        or      a
        jp      nz,e_nodos2
        ld      a,b
        cp      2
        jp      c,e_nodos2
        ; --- mapper support routines
        xor     a
        ld      de,0402h
        ld      hl,0
        call    EXTBIO
        ld      a,h
        or      l
        jp      z,e_nomap
        ld      (jt),hl
        ld      a,c
        ld      (nfree),a
        ld      de,s_free
        call    prs
        ld      a,(nfree)
        call    phex8
        ld      de,s_need
        call    prs
        ; --- choose the mode from the number of free segments: >= 19 MIDI+FM (sound menu), >= 16 FM only
        ld      a,(nfree)
        cp      N_MIDI
        jr      c,.fmonly
    IFDEF FORCE_FM
        jr      .fmonly
    ENDIF
        ld      a,N_MIDI
        ld      de,s_modem
        jr      .chosen
.fmonly: cp     N_FM
        jp      c,e_alloc
        ld      a,N_FM
        ld      de,s_modef
.chosen: ld     (nseg),a
        push    de
        call    phex8
        call    crlf
        pop     de
        call    prs
        ; --- allocate nseg user segments
        ld      hl,phys
        ld      a,(nseg)
        ld      b,a
.alloc: push    bc
        push    hl
        xor     a                       ; user segment
        ld      b,0                     ; primary mapper
        ld      hl,(jt)                 ; ALL_SEG = jt+0
        ld      de,.ret
        push    de
        jp      (hl)
.ret:   pop     hl
        pop     bc
        jp      c,e_alloc
        ld      (hl),a
        inc     hl
        djnz    .alloc
        ; unused table entries -> logical 01's segment (never 1Ch-1Fh)
        ld      a,(nseg)
        ld      c,a
        ld      a,32
        sub     c
        ld      b,a
        ld      a,(phys+1)
.fill:  ld      (hl),a
        inc     hl
        djnz    .fill
        ; --- glyph cache segments (own-font support): spare = free - nseg -> use 4, 2, 1 or 0 of them
        ld      a,(nseg)
        ld      b,a
        ld      a,(nfree)
        sub     b
        cp      4
        jr      c,.lt4
        ld      a,4
        jr      .setc
.lt4:   cp      3
        jr      c,.setc
        ld      a,2
.setc:  ld      (ncache),a
        ld      b,0                     ; ncshift = log2(ncache) for 1/2/4
        cp      2
        jr      c,.shd
        inc     b
        cp      4
        jr      c,.shd
        inc     b
.shd:   ld      a,b
        ld      (ncshift),a
        ld      a,(ncache)
        or      a
        jr      z,.nocseg
        ld      b,a
        ld      hl,cphys
.calloc: push   bc
        push    hl
        xor     a
        ld      b,0
        ld      hl,(jt)
        ld      de,.cret
        push    de
        jp      (hl)
.cret:  pop     hl
        pop     bc
        jp      c,e_alloc
        ld      (hl),a
        inc     hl
        djnz    .calloc
        ld      a,(ncache)              ; clear the tag tables (960 bytes at the start of each cache segment)
        ld      b,a
        ld      hl,cphys
.cclr:  push    bc
        push    hl
        ld      a,(hl)
        call    put_p2
        ld      hl,WIN
        ld      de,WIN+1
        ld      bc,959
        ld      (hl),0
        ldir
        pop     hl
        inc     hl
        pop     bc
        djnz    .cclr
        ld      a,1
        call    put_p2
.nocseg:
        ; --- game page 3 (P0): copy of DOS2 page 3, then our additions
        ld      a,(phys+0)
        call    put_p2
        ld      hl,0C000h
        ld      de,WIN
        ld      bc,4000h
        ldir
        ld      hl,phys                 ; TBL
        ld      de,WIN+(TBL-0C000h)
        ld      bc,32
        ldir
        ld      hl,e8eb_init            ; E8EB: page 0..3 = logical 3,2,1,0, slot 83h
        ld      de,WIN+(0E8EBh-0C000h)
        ld      bc,8
        ldir
        ld      a,20h
        ld      (WIN+(0E8F3h-0C000h)),a
        ld      hl,glyph_wrap_img       ; glyph fetch wrapper at E980h (file7 patch G1 jumps here)
        ld      de,WIN+(GLYPHW-0C000h)
        ld      bc,gw_end-glyph_wrap
        ldir
        ld      hl,WIN+(0F37Dh-0C000h)  ; F37D: JP 0090
        ld      (hl),0C3h
        inc     hl
        ld      (hl),90h
        inc     hl
        ld      (hl),00h
        ld      hl,WIN+(0FD9Ah-0C000h)  ; H.KEYI, H.TIMI -> RET (game installs its own H.KEYI)
        ld      b,10
.hk:    ld      (hl),0C9h
        inc     hl
        djnz    .hk
        ld      hl,WIN+(GSP-0C000h)     ; clear game-side vars
        ld      b,RFN+1-GSP
.cv:    ld      (hl),0
        inc     hl
        djnz    .cv
        ; --- stub into DOS2 page 0, then page-0 copies for logical 03 and 05 (and 12h for MIDI)
        ld      a,(0FCC1h)              ; EXPTBL: main ROM slot
        ld      hl,0006h
        call    000Ch                   ; RDSLT: BIOS VDP read port
        ld      (vdp_ports),a
        ld      a,(0FCC1h)
        ld      hl,0007h
        call    000Ch
        ld      (vdp_ports+1),a
        ei
        ld      a,(phys+2)
        ld      (STUB_R+(stub_p2-stub)+1),a   ; start_game: OUT (FD),phys[2]
        ld      hl,STUB_R
        ld      de,0090h
        ld      bc,stub_len
        ldir
        ld      a,(phys+3)
        call    mk_page0
        ld      a,(phys+5)
        call    mk_page0
        ld      a,(nseg)
        cp      N_MIDI
        jr      c,.nom
        ld      a,(phys+12h)            ; MIDI mode: logical 12h (player) also runs in page 0
        call    mk_page0
.nom:
        ; --- FRAY.DOS -> game page 0 at 0100h
        xor     a
        ld      (cur_disk),a
        ld      hl,FRAY_SEC
        ld      (x_sec),hl
        ld      a,FRAY_CNT
        ld      (x_cnt),a
        ld      hl,0100h
        ld      (x_addr),hl
        ld      a,2Fh
        ld      (x_fn),a
        ld      a,(phys+3)
        ld      (PH_FC),a               ; xfer picks the segment per page from PH_FC..PH_FF
        call    xfer
        ld      a,(phys+3)
        call    put_p2
        ld      a,(nseg)
        ld      (WIN+INIT_N),a          ; init_map: LD A,N (10h FM only / 13h MIDI+FM)
        ld      a,1
        call    put_p2                  ; leave DOS2's page 2 as DOS2 expects
        ld      de,s_go
        call    prs
        ; DOS2-side H.KEYI (FD9Ah, DOS2's own page 3) for the whole game session: JP dos_keyi (in this page-3 code).
        ; dos_keyi acknowledges what the BIOS interrupt handler cannot: the MSX-MIDI timer (OUT (EAh),A) and the
        ; VDP line-interrupt flag (S#1).  The game arms both; without this every EI inside DOS2 re-enters the BIOS
        ; handler forever (interrupt storm: _OPEN/_READ never returns, growing stack or livelock).
        di
        ld      hl,0FD9Ah               ; keep whatever H.KEYI held (a resident driver may use it) and run it after
        ld      de,orig_keyi
        ld      bc,5
        ldir
        ld      a,0C3h
        ld      (0FD9Ah),a
        ld      hl,dos_keyi
        ld      (0FD9Bh),hl
        ; --- enter the game environment
        di
        ld      a,(phys+0)
        out     (0FFh),a
        ld      a,(phys+1)
        out     (0FEh),a
        ld      a,(phys+3)
        out     (0FCh),a                ; page 0 is now the game's; we run from page 1
        jp      start_game              ; stub: page 1 := phys[2], SP, JP 0100h

; mk_page0: A = segment. DOS2 page 0 image (with stub) + temporary interrupt handler at 0038h
mk_page0:
        call    put_p2
        ld      hl,0000h
        ld      de,WIN
        ld      bc,0100h
        ldir
        ld      hl,int_tmp
        ld      de,WIN+0038h
        ld      bc,int_tmp_len
        ldir
        ; 0080-0087 as the original boot sector leaves them (C080h LDIR from C0FDh):
        ; 00 00 00, VDP read port, VDP write port, DISKVE address F323h, 00.
        ; the game reads (0084) as the VDP port base (palette!) and (0085) as the error-hook pointer
        ld      hl,WIN+0080h
        ld      b,8
.z:     ld      (hl),0
        inc     hl
        djnz    .z
        ld      a,(vdp_ports)
        ld      (WIN+0083h),a
        ld      a,(vdp_ports+1)
        ld      (WIN+0084h),a
        ld      hl,0F323h
        ld      (WIN+0085h),hl
        ret
int_tmp:                                ; until the loader installs JP E6CD at 0038h
        push    af
        in      a,(99h)                 ; clear VDP interrupt
        pop     af
        ei
        reti
int_tmp_len equ $-int_tmp
e8eb_init: db 3,83h,2,83h,1,83h,0,83h
dos_keyi:
        push    af
        xor     a
        out     (0EAh),a                ; MSX-MIDI interrupt acknowledge
        ld      a,1
        out     (99h),a
        ld      a,8Fh
        out     (99h),a                 ; R#15 = 1: status register S#1
        in      a,(99h)                 ; reading S#1 clears the line-interrupt flag FH
        xor     a
        out     (99h),a
        ld      a,8Fh
        out     (99h),a                 ; R#15 = 0 for the BIOS handler that follows
        pop     af
        jp      orig_keyi               ; the previous hook (RET, or a resident driver's code)
orig_keyi: db 0C9h,0C9h,0C9h,0C9h,0C9h,0C9h

; ---------------------------------------------------------------- service (DOS2 environment)
; entered from the stub: SP = dos_stack, request in game page 3 (RSEC/RHL/RFN/DTA)
dos2_service:
        xor     a                       ; VDP R15 = 0 for the BIOS interrupt handler
        out     (99h),a
        ld      a,8Fh
        out     (99h),a
        ld      a,(phys+0)
        call    put_p2
        ; physical segment of each game page at entry: TBL[E8EB[2*page]]
        ld      hl,WIN+(0E8EBh-0C000h)
        ld      de,PH_FC
        ld      b,4
.ph:    ld      a,(hl)
        cp      32
        jp      nc,e_seg                ; E8EB not initialised / corrupted
        inc     hl
        inc     hl
        push    hl
        push    bc                      ; B is the loop counter
        ld      hl,phys
        ld      c,a                     ; 16-bit add: phys may straddle a 256-byte boundary
        ld      b,0
        add     hl,bc
        pop     bc
        ld      a,(hl)
        ld      (de),a
        inc     de
        pop     hl
        djnz    .ph
        ld      a,(WIN+(RFN-0C000h))
        ld      (x_fn),a
        cp      50h                     ; 50h = glyph request (own font instead of the Kanji ROM)
        jp      z,glyph_srv
        ld      hl,(WIN+(RSEC-0C000h))
        ld      (x_sec),hl
        ld      hl,0
        ld      (x_off),hl
        ld      hl,(WIN+(RHL-0C000h))   ; L = drive, H = count
        xor     a
        ld      (force1),a
        ld      a,l
        or      a
        jr      z,.drv0
        cp      80h                     ; L=80h: music read (file13 patch M2) - song data always lives on disk 1
        jp      nz,e_drive
        ld      (force1),a
.drv0:  ld      a,h
        ld      (x_cnt),a
        ld      hl,(WIN+(DTA-0C000h))
        ld      (x_addr),hl
        ld      a,(x_fn)
        cp      2Fh
        jr      z,.rd
        cp      30h
        jr      z,.rw
        jp      e_func
.rd:    ; sector 0 = disk check: switch to the disk the game wants ((5EC0h) in page 1)
        ld      hl,(x_sec)
        ld      a,h
        or      l
        jr      nz,.rw
        ld      a,(PH_FD)
        call    put_p2
        ld      a,(WIN+(5EC0h-4000h))
        cp      8
        jr      c,.set                  ; 0..7 = disk 1..8
        cp      10
        jr      nz,.rw                  ; anything else: keep the current disk
        ld      a,8                     ; 10 = user disk
.set:   ld      (cur_disk),a
.rw:    ld      a,(force1)
        or      a
        jr      z,.norm
        ld      a,(cur_disk)            ; music read: disk 1 for this request only
        push    af
        xor     a
        ld      (cur_disk),a
        call    xfer
        pop     af
        ld      (cur_disk),a
        jr      .done
.norm:  call    xfer
.done:  xor     a
        ld      (RES),a
        ld      a,1
        call    put_p2
        jp      leave

; ---------------------------------------------------------------- transfer
; x_sec/x_off/x_cnt/x_addr/x_fn/cur_disk -> pieces of <=16KB, split at chunk and page edges
xfer:
.batch: ld      a,(x_cnt)
        or      a
        ret     z
        cp      32
        jr      c,.n
        ld      a,32
.n:     ld      b,a
        ld      a,(x_cnt)
        sub     b
        ld      (x_cnt),a
        ld      h,b
        ld      l,0
        add     hl,hl                   ; B*512
        ld      (x_left),hl
.piece: ld      hl,(x_left)
        ld      a,h
        or      l
        jr      z,.batch
        call    chunk_find              ; c_start, c_end, x_h
        ; n_chunk = min(c_end - x_sec, 32)*512 - x_off
        ld      hl,(c_end)
        ld      de,(x_sec)
        or      a
        sbc     hl,de
        ld      a,h
        or      a
        jr      nz,.cap
        ld      a,l
        cp      33
        jr      c,.ok
.cap:   ld      l,32
.ok:    ld      h,l
        ld      l,0
        add     hl,hl
        ld      de,(x_off)
        or      a
        sbc     hl,de
        ex      de,hl                   ; DE = n_chunk
        ld      hl,(x_left)
        call    min_hl_de
        push    hl
        ld      hl,(x_addr)
        ld      a,h
        and     3Fh
        ld      h,a
        ex      de,hl
        ld      hl,4000h
        or      a
        sbc     hl,de
        ex      de,hl                   ; DE = n_page
        pop     hl
        call    min_hl_de
        ld      (x_n),hl
        ; seek to (x_sec - c_start)*512 + x_off   (20-bit)
        ld      hl,(x_sec)
        ld      de,(c_start)
        or      a
        sbc     hl,de
        ld      a,l
        and     7Fh
        add     a,a
        ld      c,a                     ; high byte of low word
        ld      a,l
        rlca
        and     1
        ld      b,a
        ld      a,h
        add     a,a
        or      b
        ld      e,a                     ; bits 16..
        ld      d,0
        ld      h,c
        ld      l,0
        push    de
        ld      de,(x_off)
        add     hl,de
        pop     de
        jr      nc,.sk
        inc     de
.sk:    ld      a,(x_h)
        ld      b,a
        xor     a
        ld      c,4Ah
        call    BDOS
        or      a
        jp      nz,e_dos
        ; destination segment into page 2
        ld      a,(x_addr+1)
        rlca
        rlca
        and     3
        ld      e,a
        ld      d,0
        ld      hl,PH_FC
        add     hl,de
        ld      a,(hl)
        call    put_p2
        ld      hl,(x_addr)
        ld      a,h
        and     3Fh
        or      80h
        ld      h,a
        ex      de,hl                   ; DE = buffer
        ld      hl,(x_n)
        ld      a,(x_h)
        ld      b,a
        ld      a,(x_fn)
        ld      c,48h                   ; _READ
        cp      30h
        jr      nz,.io
        ld      c,49h                   ; _WRITE
.io:    call    BDOS
        or      a
        jp      nz,e_dos
        ld      de,(x_n)
        or      a
        sbc     hl,de
        jp      nz,e_short
        ; advance
        ld      hl,(x_addr)
        add     hl,de
        ld      (x_addr),hl
        ld      hl,(x_left)
        or      a
        sbc     hl,de
        ld      (x_left),hl
        ld      hl,(x_off)
        add     hl,de
        ld      a,h
        and     1
        ld      d,a
        ld      e,l
        ld      (x_off),de
        ld      a,h
        srl     a
        ld      e,a
        ld      d,0
        ld      hl,(x_sec)
        add     hl,de
        ld      (x_sec),hl
        jp      .piece

; ---------------------------------------------------------------- glyph service (own font)
; request: HL = (H = hi, bit6 = level; L = lo) exactly what the game wrote to the Kanji ROM ports.
; glyph index idx = (hi&3Fh)<<6 | (lo&3Fh) | (level<<12);  font file offset = idx*32 (KANJI.rom layout).
; cache: ncache (1/2/4) segments, each 480 slots: 960 bytes of tags (idx+1, 0 = empty) then 480*32 bytes of glyphs.
glyph_srv:
        ld      hl,(WIN+(RHL-0C000h))
        ld      a,h
        and     3Fh
        ld      l,a
        ld      a,(WIN+(RHL-0C000h))    ; lo
        and     3Fh
        ld      c,a
        ld      h,0
        add     hl,hl                   ; (hi&3F) << 6
        add     hl,hl
        add     hl,hl
        add     hl,hl
        add     hl,hl
        add     hl,hl
        ld      a,l
        or      c
        ld      l,a
        ld      a,(WIN+(RHL-0C000h)+1)  ; hi again for the level bit
        bit     6,a
        jr      z,.lv1
        set     4,h
.lv1:   ld      (g_idx),hl
        ld      a,(ncache)
        or      a
        jp      z,.direct
        dec     a
        and     l                       ; segment = idx & (ncache-1)
        ld      e,a
        ld      d,0
        ld      hl,cphys
        add     hl,de
        ld      a,(hl)
        ld      (g_cseg),a
        ld      hl,(g_idx)              ; slot = (idx >> ncshift) mod 480
        ld      a,(ncshift)
        or      a
        jr      z,.nsh
        ld      b,a
.sh:    srl     h
        rr      l
        djnz    .sh
.nsh:   ld      de,480
.mod:   or      a
        sbc     hl,de
        jr      nc,.mod
        add     hl,de
        ld      (g_slot),hl
        ld      a,(g_cseg)
        call    put_p2
        ld      hl,(g_slot)
        add     hl,hl
        ld      de,WIN
        add     hl,de
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        ld      hl,(g_idx)
        inc     hl
        or      a
        sbc     hl,de
        jr      nz,.miss
        call    slot_addr               ; hit
        ld      de,gbuf
        ld      bc,32
        ldir
        jr      .deliver
.miss:  call    read_glyph
        ld      a,(g_cseg)
        call    put_p2
        ld      hl,(g_slot)
        add     hl,hl
        ld      de,WIN
        add     hl,de
        ld      de,(g_idx)
        inc     de
        ld      (hl),e
        inc     hl
        ld      (hl),d
        call    slot_addr
        ex      de,hl
        ld      hl,gbuf
        ld      bc,32
        ldir
        jr      .deliver
.direct: call   read_glyph
.deliver:
        ld      a,(phys+0)              ; game page 3 back into the window, glyph -> D500h
        call    put_p2
        ld      hl,gbuf
        ld      de,WIN+(GBUF_D500-0C000h)
        ld      bc,32
        ldir
        xor     a
        ld      (RES),a
        ld      a,1
        call    put_p2
        jp      leave
slot_addr:                              ; HL = WIN + 960 + slot*32
        ld      hl,(g_slot)
        add     hl,hl
        add     hl,hl
        add     hl,hl
        add     hl,hl
        add     hl,hl
        ld      de,WIN+960
        add     hl,de
        ret
read_glyph:                             ; font file -> gbuf (32 bytes at idx*32)
        ld      a,(font_h)
        cp      0FFh
        jr      nz,.have
        ld      de,s_font
        ld      a,1                     ; read only
        ld      c,43h                   ; _OPEN
        call    BDOS
        or      a
        jp      nz,e_dos
        ld      a,b
        ld      (font_h),a
.have:  ld      a,(g_idx+1)             ; offset high word = idx >> 11
        rrca
        rrca
        rrca
        and     1Fh
        ld      e,a
        ld      d,0
        ld      hl,(g_idx)              ; offset low word = idx << 5
        add     hl,hl
        add     hl,hl
        add     hl,hl
        add     hl,hl
        add     hl,hl
        ld      a,(font_h)
        ld      b,a
        xor     a                       ; from start
        ld      c,4Ah                   ; _SEEK
        call    BDOS
        or      a
        jp      nz,e_dos
        ld      a,(font_h)
        ld      b,a
        ld      de,gbuf
        ld      hl,32
        ld      c,48h                   ; _READ
        call    BDOS
        or      a
        jp      nz,e_dos
        ret

min_hl_de:                              ; HL = min(HL,DE)
        push    hl
        or      a
        sbc     hl,de
        pop     hl
        ret     c
        ex      de,hl
        ret

; chunk_find: chunk containing x_sec on cur_disk -> c_start, c_end; file open -> x_h
chunk_find:
        ld      a,(cur_disk)
        add     a,a
        ld      e,a
        ld      d,0
        ld      hl,chunk_tables
        add     hl,de
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        ex      de,hl
        ld      b,(hl)
        inc     hl
.loop:  ld      e,(hl)
        inc     hl
        ld      d,(hl)
        inc     hl
        push    hl
        ld      hl,(x_sec)
        or      a
        sbc     hl,de
        pop     hl
        jr      c,.end
        ld      (c_start),de
        djnz    .loop
        ld      de,1440
.end:   ld      (c_end),de
        ; cached handle?
        ld      a,(cur_disk)
        ld      e,a
        ld      d,0
        ld      hl,hnd
        add     hl,de
        ld      a,(hl)
        cp      0FFh
        jr      z,.open
        push    hl
        ld      hl,hst
        add     hl,de
        add     hl,de
        ld      a,(hl)
        inc     hl
        ld      h,(hl)
        ld      l,a
        ld      de,(c_start)
        or      a
        sbc     hl,de
        pop     hl
        jr      nz,.reopen
        ld      a,(hl)
        ld      (x_h),a
        ret
.reopen:
        ld      b,(hl)
        ld      c,45h                   ; _CLOSE
        push    hl
        call    BDOS
        pop     hl
.open:  push    hl
        call    mk_name
        ld      de,fname
        ld      a,(is_save)
        xor     1                       ; save chunk: read/write (0); others: read only (1)
        ld      c,43h                   ; _OPEN
        call    BDOS
        pop     hl
        or      a
        jp      nz,e_dos
        ld      (hl),b
        ld      a,b
        ld      (x_h),a
        ld      a,(cur_disk)
        ld      e,a
        ld      d,0
        ld      hl,hst
        add     hl,de
        add     hl,de
        ld      de,(c_start)
        ld      (hl),e
        inc     hl
        ld      (hl),d
        ret

; mk_name: "\ICITY\<dir>\<tag>_<hex4>.DAT",0 into fname; is_save flag
mk_name:
        xor     a
        ld      (is_save),a
        ld      a,(cur_disk)
        ld      c,'D'
        add     a,'1'
        cp      '9'
        jr      c,.tag
        ld      a,'U'
.tag:   ld      (tag+1),a
        ld      hl,s_dir
        ld      de,fname
        call    strcpy                  ; "\ICITY\"
        ld      hl,(c_start)
        ld      de,SAVE_SEC
        or      a
        sbc     hl,de
        jr      nz,.nsv
        ld      a,(cur_disk)
        or      a
        jr      z,.sv
        cp      8
        jr      nz,.nsv
.sv:    ld      a,1
        ld      (is_save),a
        ld      hl,s_save
        ld      de,fname+7
        call    strcpy                  ; "SAVE"
        jr      .rest
.nsv:   ld      hl,tag
        ld      de,fname+7
        call    strcpy
.rest:  ld      a,5Ch                   ; backslash
        ld      (de),a
        inc     de
        ld      hl,tag
        call    strcpy
        ld      a,'_'
        ld      (de),a
        inc     de
        ld      hl,(c_start)
        ld      a,h
        call    hex2de
        ld      a,l
        call    hex2de
        ld      hl,s_dat
        call    strcpy
        xor     a
        ld      (de),a
        ret
strcpy: ld      a,(hl)                  ; copy until 0 (not copied), DE advances
        or      a
        ret     z
        ld      (de),a
        inc     hl
        inc     de
        jr      strcpy
hex2de: push    af
        rrca
        rrca
        rrca
        rrca
        call    .n
        pop     af
.n:     and     0Fh
        add     a,90h
        daa
        adc     a,40h
        daa
        ld      (de),a
        inc     de
        ret

; ---------------------------------------------------------------- helpers
put_p2: push    hl                      ; A = segment -> DOS2 page 2 (keeps DOS2's shadow right)
        push    de
        ld      hl,(jt)
        ld      de,24h
        add     hl,de
        ld      de,.r
        push    de
        jp      (hl)
.r:     pop     de
        pop     hl
        ret
prs:    push    bc
        ld      c,9
        call    BDOS
        pop     bc
        ret
pch:    push    hl
        push    de
        push    bc
        ld      e,a
        ld      c,2
        call    BDOS
        pop     bc
        pop     de
        pop     hl
        ret
crlf:   ld      a,13
        call    pch
        ld      a,10
        jp      pch
phex16: ld      a,h
        call    phex8
        ld      a,l
phex8:  push    af
        rrca
        rrca
        rrca
        rrca
        call    phexn
        pop     af
phexn:  and     0Fh
        add     a,90h
        daa
        adc     a,40h
        daa
        jp      pch

; ---------------------------------------------------------------- errors (print, back to DOS)
e_nodos2: ld    de,s_nodos2
        jr      die
e_nomap: ld     de,s_nomap
        jr      die
e_alloc: ld     de,s_alloc
        jr      die
e_drive: ld     de,s_drive
        jr      err_ctx
e_func: ld      de,s_func
        jr      err_ctx
e_seg:  ld      de,s_seg
        jr      err_ctx
e_short: ld     de,s_short
        jr      err_ctx
e_dos:  push    af
        ld      de,s_dos
        call    prs
        pop     af
        call    phex8
        ld      de,s_sp
err_ctx:
        call    prs
        ld      de,s_ctx
        call    prs
        ld      a,(x_fn)
        call    phex8
        ld      a,' '
        call    pch
        ld      hl,(x_sec)
        call    phex16
        ld      a,' '
        call    pch
        ld      a,(x_cnt)
        call    phex8
        ld      a,' '
        call    pch
        ld      hl,(x_addr)
        call    phex16
        ld      a,' '
        call    pch
        ld      de,fname
        call    prs
        ld      de,s_crlf
die:    call    prs
        ld      a,1
        call    put_p2
        ld      c,0                     ; _TERM0
        jp      BDOS

s_banner: db "ICITY DOS2 launcher",13,10,"$"
s_free:  db "mapper free segments: $"
s_need:  db " mode segments: $"
s_modem: db " MIDI+FM",13,10,"$"
s_modef: db " FM only",13,10,"$"
s_go:    db "starting",13,10,"$"
s_nodos2: db "MSX-DOS2 required",13,10,"$"
s_nomap: db "no mapper support routines",13,10,"$"
s_alloc: db "not enough free mapper segments",13,10,"$"
s_drive: db "drive not A:$"
s_func:  db "unsupported BDOS function$"
s_seg:   db "bad logical segment in E8EB$"
s_short: db "short transfer$"
s_dos:   db "DOS error $"
s_sp:    db "$"
s_ctx:   db " (fn sec cnt addr file): $"
s_crlf:  db 13,10,"$"
s_dir:   db "\\ICITY\\",0
s_font:  db "\\ICITY\\FONT.BIN",0
s_save:  db "SAVE",0
s_dat:   db ".DAT",0,"$"
tag:     db "D1",0

; ---------------------------------------------------------------- data
        INCLUDE "chunks.inc"            ; chunks_D1..DU, chunk_tables
jt:      dw 0
nfree:   db 0
nseg:    db 0
ncache:  db 0
ncshift: db 0
cphys:   ds 4,0
font_h:  db 0FFh
g_idx:   dw 0
g_slot:  dw 0
g_cseg:  db 0
gbuf:    ds 32,0
phys:    ds 32,0
cur_disk: db 0
force1:  db 0
x_sec:   dw 0
x_off:   dw 0
x_addr:  dw 0
x_cnt:   db 0
x_left:  dw 0
x_n:     dw 0
x_fn:    db 0
x_h:     db 0
c_start: dw 0
c_end:   dw 0
is_save: db 0
vdp_ports: db 98h,98h
hnd:     ds 9,0FFh
hst:     ds 18,0
fname:   ds 32,0
body_end:
        ENT
        ASSERT body_end <= 0D600h
; ---------------------------------------------------------------- stub (copied to 0090h everywhere)
stub_img:
        DISP 0090h
stub:
hook:                                   ; game: CALL F37D -> JP 0090
        ld      a,i                     ; P/V = IFF2
        di
        push    af
        ld      (GSP),sp
        ld      a,c
        cp      1Ah
        jr      nz,.go
        ld      (DTA),de
        pop     af
        jp      po,.noei
        ei
.noei:  xor     a
        ret
.go:    ld      (RSEC),de
        ld      (RHL),hl
        ld      (RFN),a
        ld      a,3
        out     (0FCh),a                ; DOS2 page 0 from here on (same bytes)
        ld      a,2
        out     (0FDh),a
        ld      a,1
        out     (0FEh),a
        xor     a
        out     (0FFh),a
        ld      sp,dos_stack
        jp      dos2_service
leave:                                  ; from dos2_service (DOS2 page 0)
        di
        ld      a,(PH_FF)
        out     (0FFh),a
        ld      a,(PH_FE)
        out     (0FEh),a
        ld      a,(PH_FD)
        out     (0FDh),a
        ld      a,(RES)
        ld      b,a
        ld      a,(PH_FC)
        out     (0FCh),a                ; game page 0 from here on
        ld      sp,(GSP)
        pop     af
        ld      a,b
        jp      po,.n
        ei
.n:     or      a
        ret
start_game:                             ; from body after FF/FE/FC are set
stub_p2:
        ld      a,0                     ; phys[2], patched at run time
        out     (0FDh),a
        ld      sp,GAME_SP
        jp      0100h
stub_end:
        ENT
stub_len equ stub_end-stub
        ASSERT stub_len <= 0070h
img_end:

; ---------------------------------------------------------------- glyph wrapper (runs in game page 3 at E980h)
; replaces the body of the game's Kanji-ROM glyph reader (file7 2AB9h, patch G1 = JP E980h).
; Same contract as the original: in HL = glyph code, out 32 bytes at D500h; the caller does not use the
; other registers, but DE/IX/IY and the alternates are saved anyway because the DOS2 side clobbers them.
glyph_wrap_img:
        DISP GLYPHW
glyph_wrap:
        ld      a,l                     ; as the original: H = (HL*4)>>8, L unchanged
        add     hl,hl
        add     hl,hl
        ld      l,a
        push    de
        push    ix
        push    iy
        ex      af,af'
        push    af
        ex      af,af'
        exx
        push    bc
        push    de
        push    hl
        exx
        ld      c,50h
        call    0F37Dh
        exx
        pop     hl
        pop     de
        pop     bc
        exx
        ex      af,af'
        pop     af
        ex      af,af'
        pop     iy
        pop     ix
        pop     de
        ld      hl,0D520h               ; where the original INIR left HL/B/C
        ld      bc,00D9h
        ret
gw_end:
        ENT
