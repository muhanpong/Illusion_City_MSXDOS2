#!/usr/bin/env python3
"""glyphscan.py - every glyph the game can draw through its Kanji-ROM reader (file 7 2AB9h): a static scan of the text.
usage: glyphscan.py <dir with D1.dsk..D8.dsk> <KANJI.rom> [out.json]

Text is Shift-JIS-like 2-byte codes (lead 81-9Fh/E0-EFh, trail 40-FCh); a byte below 40h ends a string (file 7 2A0Dh).
The glyph number is what file 7 2A85h/2A9Bh/2AB9h compute from the code (KANJI.rom layout: number*32 bytes).
Sources: dialogue in the scenes' EVT chunks (section 5 = bytecode + strings; disks 2-8), and disk 1's program files
(menus, item names, opening/ending text). Code bytes can look like text, so a run counts only when it has 2+ characters
(or 1 character between control bytes), and in the disk 1 files only when no character has a lead of 85-87h or
99h and up (real text never uses those; op-codes E1h/E5h/EBh... do). Full-width digits and Latin letters (824Fh-829Ah)
are added for numbers the game composes at run time.
Check (2026-09-30): 347 glyphs requested in 10 openMSX runs (title, opening, saves on disks 2-8) are all in the set
except two blank ones (8140h space, 825Fh). Result: 1395 non-blank glyphs, 44640 bytes."""
import sys, os, json, re
LEAD=set(range(0x81,0xa0))|set(range(0xe0,0xf0)); TRAIL=set(range(0x40,0x7f))|set(range(0x80,0xfd))
def glyph(c):
    """file 7 2A85h (row), 2A9Bh (offset), 2AB9h (ROM address bits) -> glyph number"""
    h,l=c>>8,c&0xff
    H=((h^0xA0)*2)&0xff; hl=(H<<8|l)+0xDEE1
    if l>=0x7f:
        hl-=1
        if l>=0x9f: hl+=0xA2
    hl=(hl+0xDFE0)&0xffff
    n=(hl>>8)*96+(hl&0xff)
    if (n>>8)>=4: n-=0x200
    H=((n*4)>>8)&0xff; L=n&0xff
    return (H&0x3f)<<6|(L&0x3f)|((H>>6)&1)<<12
def strings(b):
    i=0; n=len(b); cur=[]; start=0
    while i<n:
        c=b[i]
        if c in LEAD and i+1<n and b[i+1] in TRAIL:
            if not cur: start=i
            cur.append(c<<8|b[i+1]); i+=2; continue
        if cur and 0<c<0x20: i+=1; continue
        if cur: yield start,cur; cur=[]
        i+=1
    if cur: yield start,cur
def runs(b, code=False):
    for st,run in strings(b):
        end=st+2*len(run)
        if not (len(run)>=2 or ((st==0 or b[st-1]<0x20) and (end>=len(b) or b[end]<0x20))): continue
        if code and any((c>>8)>=0x99 or 0x85<=(c>>8)<=0x87 for c in run): continue
        yield run
def filetab(d):
    t=d[11*512:11*512+30]; return [(t[i],t[i+1]) for i in range(0,30,2)]
def evt_chunks(d):
    s,c=filetab(d)[6]; inf=d[s*512:(s+c)*512]
    if inf[:4]!=b'INF\0' or not (inf[6]|inf[7]<<8): return
    seen=set()
    for o in range(0x20,0x20+(inf[6]|inf[7]<<8),26):
        r=inf[o:o+26]
        for k in range(7):
            a=r[3+3*k]|r[4+3*k]<<8; cnt=r[5+3*k]
            if cnt and a not in seen and d[a*512:a*512+4]==b'EVT\0':
                seen.add(a); yield d[a*512:(a+cnt)*512]
def scan(dir_):
    codes=set(); per={}
    for n in range(2,9):
        d=open(os.path.join(dir_,f'D{n}.dsk'),'rb').read(); s=set()
        for ch in evt_chunks(d):
            lens=[ch[6+2*i]|ch[7+2*i]<<8 for i in range(5)]; so=0x20+sum(lens[:4]); sec=ch[so:so+lens[4]]
            for run in runs(sec): s.update(run)
        per[f'disk{n} EVT']=len(s); codes|=s
    d=open(os.path.join(dir_,'D1.dsk'),'rb').read(); tab=filetab(d)
    for i in (0,1,2,3,4,5,7,8,9,10,11,13,14):
        b=d[tab[i][0]*512:(tab[i][0]+tab[i][1])*512]; s=set()
        for run in runs(b, code=True): s.update(run)
        per[f'disk1 file{i}']=len(s); codes|=s
    margin=set(0x824f+i for i in range(10))|set(0x8260+i for i in range(26))|set(0x8281+i for i in range(26))
    codes|=margin
    return codes, per
if __name__=='__main__':
    codes,per=scan(sys.argv[1]); K=open(sys.argv[2],'rb').read()
    gl=sorted({glyph(c) for c in codes}); ne=[g for g in gl if K[g*32:g*32+32].count(0)!=32]
    print("codes per source:", per)
    print(f"codes {len(codes)}, glyphs {len(gl)}, non-blank {len(ne)} = {len(ne)*32} bytes ({-(-len(ne)*32//512)} sectors)")
    if len(sys.argv)>3: json.dump({'codes':sorted(codes),'glyphs':ne}, open(sys.argv[3],'w'))
