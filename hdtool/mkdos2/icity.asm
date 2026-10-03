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
    IFDEF EN8
        ; English 8-disc build (MSX Translations): the game's own page 0 (0055h-00F7h: glyph width table and code) and page 3
        ; (E000h-E96Eh: kernel and file tables) leave only 003Bh-0054h, 007Ah-007Fh and E96Fh-E9FFh to us, so the DOS2 stub shrinks to
        ; an 18-byte page switch (tramp) in page 0 and the rest (hook, leave3, variables, TBL) lives in game page 3 from E96Fh.
        DEFINE TBL      0E979h          ; logical->physical table in game page 3 (patch K1 reads it), 32 bytes
        DEFINE INIT_N   1055h           ; LD A,N immediate inside init_map (patches_en8.py), in the loader image
        DEFINE GSP      0E970h          ; game-side vars in game page 3 (E96Fh-E9FFh unused by the game)
        DEFINE DTA      0E972h
        DEFINE RSEC     0E974h
        DEFINE RHL      0E976h
        DEFINE RFN      0E978h
        DEFINE HOOKA    0E999h          ; hook (F37D entry) and leave3, after TBL
        DEFINE E8TAB    0E8B1h          ; page 0..3 -> logical segment, slot byte (4 x 2 bytes); E8FIX = number of segments cut-off
        DEFINE E8FIX    0E8B9h
        DEFINE PH_FC    0080h           ; DOS2-side page 0 vars: physical segment per page at entry (the game's copies zero 0080h-008Fh)
        DEFINE PH_FD    0081h
        DEFINE PH_FE    0082h
        DEFINE PH_FF    0083h
        DEFINE GFIN_AT  00F8h           ; game page 0 (free there): OUT (FFh),A / LD A,3 / OUT (FCh),A - then DOS2's page 0 continues at JRDC_AT
        DEFINE JRDC_AT  00FEh           ; DOS2 page 0: JR DCONT_AT
        DEFINE DCONT_AT 0090h           ; DOS2 page 0: ld sp,dos_stack / jp dos2_service
        DEFINE LEAVE_AT 0096h           ; DOS2 page 0: way back into the game: pages 3,2,1, then A = page 0 segment, JP DOUT_AT
        DEFINE DOUT_AT  007Ah           ; DOS2 page 0 (the default FCB area): OUT (FCh),A - then the game's page 0 continues at GCONT_AT (JP leave3)
        DEFINE GCONT_AT 007Ch
        DEFINE GAME_SP  0FAF8h          ; the original boot sector's stack
        DEFINE UI_BLK_B 0DD30h          ; 38 free bytes (DD30h-DD55h): newlist, cbk
    ELSE
        DEFINE TBL      0E960h          ; logical->physical table in game page 3 (patch K1 reads it)
        DEFINE INIT_N   0DB6h           ; LD A,N immediate inside init_map (patches.py INIT_MAP_N)
        DEFINE GSP      0E948h          ; game-side vars in game page 3 (E947-E95F unused by game)
        DEFINE DTA      0E94Ah
        DEFINE RSEC     0E94Ch
        DEFINE RHL      0E94Eh
        DEFINE RFN      0E950h
        DEFINE E8TAB    0E8EBh
        DEFINE E8FIX    0E8F3h
        DEFINE PH_FC    0080h           ; DOS2-side page 0 vars: physical segment per page at entry
        DEFINE PH_FD    0081h
        DEFINE PH_FE    0082h
        DEFINE PH_FF    0083h
        DEFINE RES      0084h           ; result for the game (A)
        DEFINE GAME_SP  0F300h          ; loader stack until the kernel sets FAF8h
    ENDIF
        DEFINE WIN      8000h           ; DOS2 page 2 window
        DEFINE INP      0055h           ; slot-list input in game page 0 (FCB area)
        DEFINE GLYPHW   0E980h          ; glyph wrapper in game page 3 (E947-E9FF unused by the game)
        DEFINE GBUF_D500 0D500h         ; the game's glyph buffer
        DEFINE BDOS     0005h
        DEFINE EXTBIO   0FFCAh
        DEFINE dos_stack 0D700h         ; DOS2-side stack: page 3 TPA. The kernel swaps page 0 (segment 1Ah) and page 1 (ROM) during calls,
                                        ; so stack, code and parameter buffers all live in page 3 (C000-D5FF); page 2 is the window
    IFDEF EN8
        DEFINE FRAY_SEC 11              ; the boot sector's 8 sectors (0Bh-12h) -> 0100h; then 0D46h with 0100h pushed
        DEFINE FRAY_CNT 8
    ELSE
        DEFINE FRAY_SEC 14
        DEFINE FRAY_CNT 7
    ENDIF
        DEFINE SAVE_SEC 0578h
        DEFINE EXTSEC   0600h           ; save slots 9-96 (paged slot list, patches P1-P6): sector EXTSEC + 2*(slot-8)
        DEFINE SLOTS    96              ; per disk; the save files hold them all (96KB, slot n at n*1KB)
        DEFINE UI_SECOF   0E9D8h        ; slot-list paging entry points (patches.py P1-P6 use the same numbers)
        DEFINE UI_NEWLIST 0E9E7h
        DEFINE UI_FIXNO   0E9F4h
        DEFINE UI_FIXSEL  00F6h

; ---------------------------------------------------------------- .COM header: move body to C000h
        ORG 0100h
        ld      hl,body_img
        ld      de,0C000h
        ld      bc,img_end-body_img
        ldir
        jp      body
    IFNDEF EN8
STUB_R  equ 0C000h+(stub_img-body_img)  ; relocated address of the stub image
    ENDIF
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
        call    grow_saves
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
        ld      de,WIN+(E8TAB-0C000h)
        ld      bc,8
        ldir
        ld      a,20h
        ld      (WIN+(E8FIX-0C000h)),a
    IFDEF EN8
        ld      hl,hook_img             ; F37D entry (hook) and its way back (leave3), game page 3
        ld      de,WIN+(HOOKA-0C000h)
        ld      bc,hook_end-hook
        ldir
        ld      hl,ui_blk_img           ; slot list paging, game side, second block
        ld      de,WIN+(UI_BLK_B-0C000h)
        ld      bc,ui_blk_len
        ldir
        ld      hl,WIN+(0F37Dh-0C000h)  ; F37D: JP hook
        ld      (hl),0C3h
        inc     hl
        ld      (hl),HOOKA & 0FFh
        inc     hl
        ld      (hl),HOOKA >> 8
    ELSE
        ld      hl,glyph_wrap_img       ; glyph fetch wrapper at E980h (file7 patch G1 jumps here)
        ld      de,WIN+(GLYPHW-0C000h)
        ld      bc,gw_end-glyph_wrap
        ldir
        ld      hl,ui_img               ; slot-list paging (file9 patches P1-P6 call it)
        ld      de,WIN+(0E9AAh-0C000h)
        ld      bc,ui_end-cbk
        ldir
        ld      hl,ui2_img
        ld      de,WIN+(0E951h-0C000h)
        ld      bc,ui2_end-pkey
        ldir
        ld      hl,WIN+(0F37Dh-0C000h)  ; F37D: JP 0090
        ld      (hl),0C3h
        inc     hl
        ld      (hl),90h
        inc     hl
        ld      (hl),00h
    ENDIF
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
    IFDEF EN8
        ld      hl,DCONT_R              ; DOS2's own page 0 (0080h-00FFh is ours): continuation into dos2_service, leave, JR, OUT (FCh),A
        ld      de,DCONT_AT
        ld      bc,dcont_len
        ldir
        ld      hl,LEAVEDOS_R
        ld      de,LEAVE_AT
        ld      bc,leave_dos_len
        ldir
        ld      hl,JRDC_R
        ld      de,JRDC_AT
        ld      bc,2
        ldir
        ld      hl,DOUT_R
        ld      de,DOUT_AT
        ld      bc,2
        ldir
    ELSE
        ld      a,(phys+2)
        ld      (STUB_R+(stub_p2-stub)+1),a   ; start_game: OUT (FD),phys[2]
        ld      hl,STUB_R
        ld      de,0090h
        ld      bc,stub_len
        ldir
    ENDIF
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
        out     (0FCh),a                ; page 0 is now the game's; we run from page 3 (same code in the game's copy)
    IFDEF EN8
        ld      a,(phys+2)
        out     (0FDh),a                ; page 1
        ld      sp,GAME_SP              ; what the boot sector leaves: PUSH 0100h, JP 0D46h (copies the game's page-0 code, then RET 0100h)
        ld      hl,0100h
        push    hl
        jp      0D46h
    ELSE
        jp      start_game              ; stub: page 1 := phys[2], SP, JP 0100h
    ENDIF

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
    IFDEF EN8
        ld      hl,GFIN_R               ; game -> DOS2 at 007Ah; DOS2 -> game continues at 00FAh (JP leave3)
        ld      de,WIN+GFIN_AT
        ld      bc,gfin_len
        ldir
        ld      hl,GCONT_R
        ld      de,WIN+GCONT_AT
        ld      bc,gcont_len
        ldir
    ELSE
        ld      hl,inp_img              ; slot-list input (cbk) at 0055h: the FCB area, never used in the game world
        ld      de,WIN+INP
        ld      bc,inp_end-inp
        ldir
    ENDIF
        ; 0080-0087 as the original boot sector leaves them (C080h LDIR from C0FDh):
        ; 00 00 00, VDP read port, VDP write port, DISKVE address F323h, 00.
        ; the game reads (0084) as the VDP port base (palette!) and (0085) as the error-hook pointer
        ld      hl,WIN+0080h
    IFDEF EN8
        ld      b,16                    ; 0088h/0089h are live variables of the game's interrupt handler (E6B2h, E702h): they must start at 0
    ELSE
        ld      b,8
    ENDIF
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
        ld      hl,WIN+(E8TAB-0C000h)
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
    IFDEF EN8
        cp      51h                     ; 51h = slot list keys (page left/right), see ui_srv
        jp      z,ui_srv
    ENDIF
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
    IFNDEF EN8
        ld      (RES),a
    ENDIF
        ld      a,1
        call    put_p2
    IFDEF EN8
        di
        jp      LEAVE_AT
    ELSE
        jp      leave
    ENDIF

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
        ; seek to (x_sec - c_base)*512 + x_off   (20-bit)
        ld      hl,(x_sec)
        ld      de,(c_base)
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
    IFNDEF EN8
        ld      (RES),a
    ENDIF
        ld      a,1
        call    put_p2
    IFDEF EN8
        di
        jp      LEAVE_AT
    ELSE
        jp      leave
    ENDIF
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

; chunk_find: chunk containing x_sec on cur_disk -> c_start, c_end, c_base (file position = (x_sec - c_base)*512);
; file open -> x_h. Sectors >= EXTSEC of disk 1 / the user disk are save slots 9-96: the save chunk (0578h),
; after its own 16 sectors.
chunk_find:
        ld      a,(cur_disk)
        or      a
        jr      z,.sv
        cp      8
        jr      nz,.nosv
.sv:    ld      hl,(x_sec)
        ld      de,EXTSEC
        or      a
        sbc     hl,de
        jr      c,.nosv
        ld      hl,SAVE_SEC
        ld      (c_start),hl
        ld      hl,EXTSEC-16
        ld      (c_base),hl
        ld      de,EXTSEC+(SLOTS-8)*2
        jr      .end2
.nosv:
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
.end:   ld      hl,(c_start)
        ld      (c_base),hl
.end2:  ld      (c_end),de
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

; grow_saves: the save files hold SLOTS slots (96KB) since the paged slot list; older 8KB ones grow here (zeros).
; Runs at start, while page 2 is still DOS2's TPA (8000h-81FFh = zero buffer).
grow_saves:
        ld      hl,8000h
        ld      de,8001h
        ld      bc,511
        ld      (hl),0
        ldir
        xor     a
        call    .one
        ld      a,8
        call    .one
        xor     a
        ld      (cur_disk),a            ; the game starts on disk 1
        ret
.one:   ld      (cur_disk),a
        ld      hl,SAVE_SEC
        ld      (c_start),hl
        call    mk_name
        ld      de,fname
        xor     a                       ; read/write
        ld      c,43h                   ; _OPEN
        call    BDOS
        or      a
        jp      nz,e_dos
        ld      a,b
        ld      (x_h),a
        ld      de,0
        ld      hl,0
        ld      a,2                     ; from the end: DE:HL = size
        ld      c,4Ah                   ; _SEEK
        call    BDOS
        or      a
        jp      nz,e_dos
.lp:    ld      a,d                     ; size < SLOTS*1KB (18000h)?
        or      a
        jr      nz,.done
        ld      a,e
        cp      1
        jr      c,.wr
        jr      nz,.done
        bit     7,h
        jr      nz,.done
.wr:    push    de
        push    hl
        ld      a,(x_h)
        ld      b,a
        ld      de,8000h
        ld      hl,512
        ld      c,49h                   ; _WRITE
        call    BDOS
        or      a
        jp      nz,e_dos
        pop     hl
        pop     de
        ld      bc,512
        add     hl,bc
        jr      nc,.lp
        inc     de
        jr      .lp
.done:  ld      a,(x_h)
        ld      b,a
        ld      c,45h                   ; _CLOSE
        jp      BDOS

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

    IFDEF EN8
; ---------------------------------------------------------------- slot list paging (DOS2 side, English build)
; The game's menu loop calls cbk (game page 3, patch P1) once per iteration; cbk asks us (function 51h) to look at the keys.
; Keyboard row 8 and joystick 1, moved to the same bits as the Korean build's inp: bit 4 left, bit 7 keyboard right, bit 5 joystick right
; (0 = pressed); a newly pressed left/right changes the page variable in game page 3 (0..SLOTS/8-1).  cbk redraws when it changed.
ui_srv:
        call    ui_inp
        cpl
        and     0B0h
        ld      hl,ui_pkey
        ld      c,(hl)
        ld      (hl),a
        ld      b,a
        ld      a,c
        cpl
        and     b                       ; newly pressed
        ld      e,a
        ld      a,(phys+0)              ; game page 3 (the window may have been moved)
        call    put_p2                  ; keeps DE and HL
        ld      hl,WIN+(UI_PAGE-0C000h)
        ld      a,e
        rla
        jr      c,.right
        bit     6,a                     ; joystick right
        jr      nz,.right
        and     20h                     ; left
        jr      z,.done
        ld      a,(hl)
        or      a
        jr      z,.done
        dec     (hl)
        jr      .done
.right: ld      a,(hl)
        cp      SLOTS/8-1
        jr      nc,.done
        inc     (hl)
.done:  ld      a,1
        call    put_p2
        di
        jp      LEAVE_AT
ui_pkey: db     0
ui_inp: in      a,(0AAh)                ; keyboard row 8 (the BIOS selects its row itself before each scan)
        and     0F0h
        or      8
        out     (0AAh),a
        ld      a,15
        out     (0A0h),a
        in      a,(0A2h)
        and     0BFh                    ; joystick port 1
        out     (0A1h),a
        ld      a,14
        out     (0A0h),a
        in      a,(0A2h)                ; bit 2 left, bit 3 right
        rlca
        rlca                            ; left -> bit 4, right -> bit 5
        or      0CFh
        ld      d,a
        in      a,(0A9h)                ; keyboard: bit 4 left, bit 7 right
        or      6Fh
        and     d
        ret
    ENDIF

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
c_base:  dw 0
is_save: db 0
vdp_ports: db 98h,98h
hnd:     ds 9,0FFh
hst:     ds 18,0
fname:   ds 32,0
body_end:
        ENT
        ASSERT body_end <= 0D600h
    IFDEF EN8
; ---------------------------------------------------------------- English 8-disc build: page switch, hook, leave3
; The game's page 0 holds the DOS2 page-0 image (RST vectors, 003Bh-0054h slot-switch helpers the page-3 jump table calls) and the
; game's own code and tables (0055h-00F7h), so only 007Ah-007Fh and 00F8h-00FFh are free there.  The page switch needs code at the
; same address in both environments' page 0 only for its last instruction (OUT (FCh),A); everything else runs in page 3 or
; in the part of page 0 that belongs to one environment.
;   game -> DOS2: hook (game page 3) switches pages 2 and 1, A = 0, JP GFIN_AT (00F8h, game page 0): OUT (FFh),A / LD A,3 /
;                 OUT (FCh),A; DOS2's page 0 continues at 00FEh: "jr DCONT_AT" -> "ld sp,dos_stack / jp dos2_service".
;   DOS2 -> game: dos2_service -> JP LEAVE_AT (DOS2 page 0): the game's pages 3,2,1 from PH_FF..PH_FD, A = PH_FC, JP DOUT_AT
;                 (007Ah, DOS2 page 0): OUT (FCh),A, and the game's page 0 continues at 007Ch with "jp leave3" (game page 3: SP, flags, RET).
; DOS2's page 0: the default FCB area 007Ah-007Fh and 0080h-00FFh (the command line buffer) are ours - the same area the Korean stub used.
; The game's copies of 0080h-008Fh start as zeros (mk_page0): the interrupt handler reads (0088h)/(0089h) as soon as the loader's EI runs.
img_end:
GFIN_R   equ gfin_img
GCONT_R  equ gcont_img
DCONT_R  equ dcont_img
LEAVEDOS_R equ leave_dos_img
DOUT_R   equ dout_img
JRDC_R   equ jrdc_img
gfin_img:
        DISP GFIN_AT
        out     (0FFh),a                ; A = 0: DOS2 page 3 (segment 0)
        ld      a,3
        out     (0FCh),a                ; DOS2 page 0 from here on (segment 3)
gfin_end:
        ENT
gfin_len equ gfin_end-GFIN_AT
        ASSERT GFIN_AT+gfin_len <= JRDC_AT
gcont_img:
        DISP GCONT_AT
        jp      leave3                  ; the game's page 0 is back
gcont_end:
        ENT
gcont_len equ gcont_end-GCONT_AT
        ASSERT GCONT_AT+gcont_len <= 0080h
dcont_img:
        DISP DCONT_AT
        ld      sp,dos_stack
        jp      dos2_service
dcont_end:
        ENT
dcont_len equ dcont_end-DCONT_AT
leave_dos_img:
        DISP LEAVE_AT
        ld      a,(PH_FF)
        out     (0FFh),a                ; game page 3
        ld      a,(PH_FE)
        out     (0FEh),a                ; page 2
        ld      a,(PH_FD)
        out     (0FDh),a                ; page 1
        ld      a,(PH_FC)
        jp      DOUT_AT
leave_dos_end:
        ENT
leave_dos_len equ leave_dos_end-LEAVE_AT
        ASSERT DCONT_AT+dcont_len <= LEAVE_AT && LEAVE_AT+leave_dos_len <= JRDC_AT
jrdc_img:
        DISP JRDC_AT
        jr      DCONT_AT                ; DOS2 page 0: reached after the game's OUT (FCh),A at GFIN_AT
jrdc_end:
        ENT
dout_img:
        DISP DOUT_AT
        out     (0FCh),a                ; the game's page 0 from here on
dout_end:
        ENT
hook_img:
        DISP HOOKA
hook:   ld      a,i                     ; game: CALL F37D -> JP hook.  P/V = IFF2
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
        ld      a,1
        out     (0FEh),a                ; DOS2's page 2 (segment 1) and page 1 (segment 2); the stack and this code stay in game page 3
        inc     a
        out     (0FDh),a
        xor     a
        jp      GFIN_AT
leave3: ld      sp,(GSP)                ; from tramp (game page 0), the game's mapping is back
        pop     af
        ld      a,0
        jp      po,.n
        ei
.n:     or      a
        ret
; slot list paging, game side (patches_en8.py P1-P6 call these; addresses are asserted below)
secof:  ld      hl,SAVE_SEC             ; P5/P6: sector of slot E (D = 0); slots 9-96 live at EXTSEC + 2*(slot-8)
        ld      a,e
        sub     8
        jr      c,.lo
        ld      e,a
        ld      hl,EXTSEC
.lo:    add     hl,de
        add     hl,de
        ret
fixno:  ld      b,a                     ; P2: number shown = page*8 + row (B is free there)
        call    pg8
        ld      (0D56Ah),a
        ld      a,b
        ret
pg8:    ld      a,(UI_PAGE)             ; A = page*8 + B
        add     a,a
        add     a,a
        add     a,a
        add     a,b
        ret
fixsel: ld      b,a                     ; P3: slot selected = page*8 + row
        call    pg8
        ld      (5EC5h),a
        ret
ui_page: db     0
UI_PAGE equ ui_page
hook_end:
        ENT
        ASSERT hook_end <= 0EA00h && TBL+32 <= HOOKA
ui_blk_img:
        DISP UI_BLK_B
newlist: ld     a,(5EC3h)               ; P4: opening the list; SRAM / Quick (8 slots) start on page 0
        cp      3
        jr      nc,.keep
        xor     a
        ld      (UI_PAGE),a
.keep:  jp      5944h                   ; rebuild the 8 rows
cbk:    ld      a,(5EC3h)               ; P1: called by the menu loop (file7 308Ah) once per iteration; medium 1 Quick, 2 SRAM, 3 disk 1, 4 user disk
        cp      3
        ret     c
        ld      a,(UI_PAGE)
        push    af
        ld      c,51h                   ; DOS2 side looks at the keys and may change the page
        call    0F37Dh
        pop     bc
        ld      a,(UI_PAGE)
        cp      b
        ret     z
        jp      5944h
ui_blk_end:
        ENT
ui_blk_len equ ui_blk_end-UI_BLK_B
        ASSERT UI_BLK_B+ui_blk_len <= 0DD56h
        ASSERT secof == 0E9D3h && fixno == 0E9E2h && fixsel == 0E9F3h && newlist == 0DD30h && cbk == 0DD3Eh   ; patches_en8.py P1-P6 use these
    ELSE
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
fixsel: ld      b,a                     ; P3 5910h: slot selected = page*8 + row (file7's page-0 segment has it too)
        call    pg8
        ld      (5EC5h),a
        ret
stub_end:
        ENT
stub_len equ stub_end-stub
        ASSERT stub_len <= 0070h
img_end:
    ENDIF

    IFNDEF EN8
; ---------------------------------------------------------------- slot-list paging (game page 3 E9AAh-E9FFh + E951h-E95Fh)
; The game's slot list (file9 58C0h) shows 8 slots; file9 patches P1-P6 (patches.py, fixed addresses checked below)
; make it show page*8+1 .. page*8+8, left/right switching pages on the disk media (SRAM / Quick stay as they are): keyboard or
; joystick 1 (inp in game page 0).
; Only launcher-owned bytes are used: the DOS2 kernel copy in game page 3 (e.g. Nextor's F1E8h jump table) is live.
ui_img:
        DISP 0E9AAh
cbk:    ld      a,(5EC3h)               ; P1 590Ah LD HL,cbk: called by the menu loop (file7 308Ah)
        cp      3                       ; medium: 1 Quick, 2 SRAM, 3 disk 1, 4 user disk
        ret     c
        call    INP                     ; keyboard row 8 + joystick 1 (0 = pressed)
        cpl
        and     0B0h                    ; bit 4 left, bit 7 right, bit 5 joystick right
        ld      hl,pkey
        ld      c,(hl)
        ld      (hl),a
        ld      b,a
        ld      a,c
        cpl
        and     b                       ; newly pressed
        inc     hl                      ; page
        rla
        jr      c,.right
        bit     6,a                     ; joystick right
        jr      nz,.right
        and     20h
        ret     z
        ld      a,(hl)
        or      a
        ret     z
        dec     (hl)
        jr      .set
.right: ld      a,(hl)
        cp      SLOTS/8-1
        ret     nc
        inc     (hl)
.set:   jp      5944h                   ; rebuild the 8 rows
secof:  ld      hl,SAVE_SEC             ; P5/P6 5A66h/5A8Fh: sector of slot E (D = 0)
        ld      a,e
        sub     8
        jr      c,.lo
        ld      e,a
        ld      hl,EXTSEC
.lo:    add     hl,de
        add     hl,de
        ret
newlist: ld     a,(5EC3h)               ; P4 58E3h: opening the list; SRAM (8 slots) starts on page 0
        cp      3
        jr      nc,.keep
        xor     a
        ld      (page),a
.keep:  jr      cbk.set
fixno:  ld      b,a                     ; P2 5957h: number shown = page*8 + row (B is free there)
        call    pg8
        ld      (0D56Ah),a
        ld      a,b
        ret
ui_end:
        ENT
        ASSERT ui_end <= 0EA00h
ui2_img:
        DISP 0E951h
pkey:   db      0
page:   db      0                       ; right after pkey (cbk)
pg8:    ld      a,(page)                ; A = page*8 + B
        add     a,a
        add     a,a
        add     a,a
        add     a,b
        ret
ui2_end:
        ENT
        ASSERT ui2_end <= 0E960h        ; TBL
        ; patches.py (P1-P6) uses these addresses
    IFNDEF EN8
        ASSERT cbk == 0E9AAh && fixno == UI_FIXNO && fixsel == UI_FIXSEL && newlist == UI_NEWLIST && secof == UI_SECOF
    ENDIF

; ---------------------------------------------------------------- slot-list input (game page 0 0055h-007Fh)
; The FCB area of the DOS2 page-0 image: mk_page0 puts this in every game page-0 segment (logical 03, 05, 12h).
; A = keyboard row 8 AND joystick 1 moved to the same places: bit 4 left, bit 7 keyboard right, bit 5 joystick
; right (keyboard bit 5 = up is masked out); 0 = pressed. PSG R15 is left on port 1 (bit 6 = 0), the other bits kept.
inp_img:
        DISP INP
inp:    in      a,(0AAh)                ; keyboard row 8 (the BIOS selects its row itself before each scan)
        and     0F0h
        or      8
        out     (0AAh),a
        di                              ; the game's interrupt handler also writes the PSG
        ld      a,15
        out     (0A0h),a
        in      a,(0A2h)
        and     0BFh                    ; joystick port 1
        out     (0A1h),a
        ld      a,14
        out     (0A0h),a
        in      a,(0A2h)                ; bit 2 left, bit 3 right
        ei
        rlca
        rlca                            ; left -> bit 4, right -> bit 5
        or      0CFh
        ld      d,a
        in      a,(0A9h)                ; keyboard: bit 4 left, bit 7 right
        or      6Fh
        and     d
        ret
inp_end:
        ENT
        ASSERT inp_end <= 0080h

    ENDIF
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
