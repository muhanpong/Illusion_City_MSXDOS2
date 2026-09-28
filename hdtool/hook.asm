; Illusion City HD loader patch: BDOS F37D hook that maps the 9 virtual disks
; (8 game disks + user disk) onto one big emulated disk image.
        OUTPUT "hookpatch.bin"
        ORG 0x0DA2                      ; appended at end of original FRAY.DOS (0x100 + 0xCA2)
install:
        ld      hl,hookimg
        ld      de,0x0090
        ld      bc,hookend-hook
        ldir
        ld      hl,(0xF37E)             ; original BDOS jump target
        ld      (0x0090 + (orig+1-hook)),hl
        ld      hl,0x0090
        ld      (0xF37E),hl             ; F37D: JP 0090
        ld      hl,0x045B               ; instruction we replaced at FRAY.DOS start
        jp      0x0103
hookimg:
        DISP    0x0090
hook:   ld      a,c
        cp      0x2F                    ; absolute sector read
        jr      z,rw
        cp      0x30                    ; absolute sector write
        jr      z,rw
orig:   jp      0                       ; patched with original target
rw:     ld      a,l                     ; L = drive, 0 = default (A:)
        or      a
        jr      nz,orig
        ld      a,d
        or      e
        jr      nz,addbase
        ; sector 0 = disk identification read: switch to the disk the game wants
        ld      a,(0x5EC0)              ; wanted disk, 0-based (engine file 9, mapped in page 1 by caller)
        cp      8
        jr      c,plus1                 ; 0..7 = game disks 1..8
        cp      10
        jr      nz,addbase              ; anything else: keep current disk
        ld      a,8                     ; 10 = "user disk" -> region 9
plus1:  inc     a
        ld      (cur),a
addbase:
        push    hl
        ld      a,(cur)
        dec     a
        add     a,a
        add     a,LOW tbl
        ld      l,a
        ld      h,HIGH tbl
        ld      a,(hl)
        add     a,e
        ld      e,a
        inc     hl
        ld      a,(hl)
        adc     a,d
        ld      d,a
        pop     hl
        jr      orig
cur:    db      1
tbl:    dw      0*1440,1*1440,2*1440,3*1440,4*1440,5*1440,6*1440,7*1440,8*1440
hookend:
        ENT
        ASSERT  hookend-hook <= 0x70
