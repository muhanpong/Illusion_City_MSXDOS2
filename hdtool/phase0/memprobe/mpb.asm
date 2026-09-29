; MPB.BIN - BASIC BLOAD probe: DOS2 mapper table + ALL_SEG all free user segments
; results at 0D000h: +0 E1 entry(8 bytes) +8 E2: A,B,C  +0Bh count  +10h.. segment list
        OUTPUT "MPB.BIN"
        db 0FEh : dw begin, endc, begin
        ORG 0C000h
EXTBIO  equ 0FFCAh
RES       equ 0D000h
begin:  di : ld hl,RES : ld de,RES+1 : ld bc,0FFh : ld (hl),0 : ldir : ei
        ld a,(0FB20h) : ld (RES+0Ch),a       ; HOKVLD
        xor a : ld de,0401h : call EXTBIO
        ld (RES+0Dh),a
        ld de,RES : ld bc,8 : ldir
        xor a : ld de,0402h : call EXTBIO
        ld (RES+8),a : ld a,b : ld (RES+9),a : ld a,c : ld (RES+0Ah),a
        ld (jt),hl
        ld ix,RES+10h
lp:     ld b,0 : xor a
        ld hl,rt : push hl : ld hl,(jt) : jp (hl)
rt:     jr c,done
        ld (ix+0),a : inc ix
        ld hl,RES+0Bh : inc (hl) : ld a,(hl) : cp 0E0h : jr c,lp
done:   ret
jt:     dw 0
endc:
