; MEMPROBE.COM - report TPA top and DOS2 mapper segment availability
        OUTPUT "MEMPROBE.COM"
        ORG 0100h
BDOS    equ 0005h
EXTBIO  equ 0FFCAh
start:
        ld de,s_tpa : call prs
        ld hl,(0006h) : call phex16 : call crlf
        ld de,s_sp : call prs
        ld hl,0 : add hl,sp : call phex16 : call crlf
        ; --- mapper variable table
        ld hl,0FFFFh
        xor a : ld de,0401h : call EXTBIO
        ld (e1a),a : ld (e1hl),hl
        ld de,s_tbl : call prs : ld a,(e1a) : call phex8
        ld a,' ' : call pch : ld hl,(e1hl) : call phex16 : call crlf
        ld hl,(e1hl)
        ld b,4
tloop:  ld a,(hl) : or a : jr z,tdone
        push bc : push hl
        ld de,s_ent : call prs
        pop hl : push hl
        ld b,5
eloop:  ld a,(hl) : call phex8 : ld a,' ' : call pch : inc hl : djnz eloop
        call crlf
        pop hl : ld de,8 : add hl,de : pop bc
        djnz tloop
tdone:
        ; --- mapper support routine info
        xor a : ld de,0402h : call EXTBIO
        ld (jt),hl : ld (pslot),a
        push bc
        ld de,s_sup : call prs
        ld a,(pslot) : call phex8 : ld a,' ' : call pch           ; total
        pop bc : push bc
        ld a,b : call phex8 : ld a,' ' : call pch  ; slot
        pop bc
        ld a,c : call phex8 : call crlf            ; free
        ; --- actually allocate user segments from primary until failure
        ld de,s_alp : call prs
        ld b,0 : call allocall : call crlf
        ; --- then from other mapper slots (xxx=001 relative to primary)
        ld de,s_alo : call prs
        ld a,(xslot) : or 10h : ld b,a : call allocall : call crlf
        ld de,s_end : call prs
        ld c,0 : jp BDOS                          ; exit (user segments auto-freed)

; allocate repeatedly with B param, print count, first, last
allocall:
        ld a,b : ld (bpar),a
        xor a : ld (cnt),a : ld a,0FFh : ld (first),a : ld (last),a
aloop:  ld a,(bpar) : ld b,a : xor a
        ld hl,aret : push hl
        ld hl,(jt) : jp (hl)                      ; ALL_SEG (jt+0)
aret:   jr c,adone
        ld (last),a
        ld hl,first : ld c,a : ld a,(hl) : cp 0FFh : jr nz,anf : ld (hl),c
anf:    ld hl,cnt : inc (hl)
        ld a,b : ld (xslot),a
        ld a,(cnt) : cp 250 : jr c,aloop
adone:  ld a,(cnt) : call phex8 : ld a,' ' : call pch
        ld a,(first) : call phex8 : ld a,'-' : call pch
        ld a,(last) : call phex8
        ret

prs:    ld c,9 : jp BDOS
pch:    push hl : push de : push bc : ld e,a : ld c,2 : call BDOS : pop bc : pop de : pop hl : ret
crlf:   ld a,13 : call pch : ld a,10 : jp pch
phex16: ld a,h : call phex8 : ld a,l
phex8:  push af : rrca : rrca : rrca : rrca : call phexn : pop af
phexn:  and 0Fh : add a,90h : daa : adc a,40h : daa : jp pch

s_tpa:  db "TPA top (0006)=$"
s_sp:   db "SP=$"
s_tbl:  db "E=1 A,HL=$"
s_ent:  db "slot total free sys user: $"
s_sup:  db "E=2 total slot free: $"
s_alp:  db "ALL_SEG primary: n first-last $"
s_alo:  db "ALL_SEG others : n first-last $"
s_end:  db "END$"
jt:     dw 0
e1a:    db 0
e1hl:   dw 0
pslot:  db 0
xslot:  db 0
bpar:   db 0
cnt:    db 0
first:  db 0
last:   db 0
