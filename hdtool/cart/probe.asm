; probe.asm - minimal cartridge: INIT hooks H.STKE and H.RUNC, the hook routines just record that they ran.
        OUTPUT "probe.rom"
        ORG 4000h
        db "AB"
        dw init, 0, 0, 0, 0, 0, 0
init:   call    0138h                   ; RSLREG
        rrca
        rrca
        and     3                       ; primary slot of page 1
        ld      c,a
        ld      b,0
        ld      hl,0FCC1h               ; EXPTBL
        add     hl,bc
        ld      a,(hl)
        and     80h
        or      c
        ld      c,a
        inc     hl
        inc     hl
        inc     hl
        inc     hl
        ld      a,(hl)                  ; SLTTBL
        and     0Ch
        or      c
        ld      (0FEDBh),a              ; H.STKE: RST 30h, slot, addr
        ld      (0FECCh),a              ; H.RUNC
        ld      a,0F7h
        ld      (0FEDAh),a
        ld      (0FECBh),a
        ld      hl,on_stke
        ld      (0FEDCh),hl
        ld      hl,on_runc
        ld      (0FECDh),hl
        ld      a,0C9h
        ld      (0FEDEh),a
        ld      (0FECFh),a
        ret
on_stke: nop
        ret
on_runc: nop
        ret
        ds 4000h-($-4000h),0FFh
