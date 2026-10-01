#!/usr/bin/env python3
"""segan.py - names what each 16KB segment of a RAM dump holds (matches disk 1 and the current disk sector by sector).
Paths are those of the session that wrote it (sg/<run>/ram.bin, fdd3/D*.dsk): edit them before use."""
import collections,sys
d1=open('fdd3/D1.dsk','rb').read()
t=d1[11*512:11*512+30]; tab=[(t[i],t[i+1]) for i in range(0,30,2)]
def lab1(s):
    for i,(a,c) in enumerate(tab):
        if a<=s<a+c: return f'f{i}'
    if 0x14A<=s<=0x2C8: return 'song'
    if 0x2C9<=s<=0x54D: return 'D1gfx'
    if 0x550<=s<=0x575: return 'font'
    return 'x'
def typemap(dn):
    d=open(f'fdd3/D{dn}.dsk','rb').read(); ft=[(d[11*512+2*i],d[11*512+2*i+1]) for i in range(15)]
    s0,c0=ft[6]; inf=d[s0*512:(s0+c0)*512]; ln0=inf[6]|inf[7]<<8; m={}
    for o in range(0x20,0x20+ln0,26):
        r=inf[o:o+26]
        for k in range(7):
            a=r[3+3*k]|r[4+3*k]<<8; c=r[5+3*k]
            if c:
                mg=d[a*512:a*512+3]; ty='EVT' if mg==b'EVT' else 'map' if mg==b'map' else 'chk'
                for s in range(a,a+c): m[s]=ty
    for i,(a,c) in enumerate(ft):
        for s in range(a,a+c): m.setdefault(s,f'f{i}')
    return d,m
def run(j,dn,midi):
    R=open(f'sg/{j}/ram.bin','rb').read(); dd,tm=typemap(dn)
    cnt=collections.defaultdict(collections.Counter)
    for name,d,lab in (('D1',d1,lab1),(f'D{dn}',dd,lambda s,tm=tm:'D%d-%s'%(dn,tm.get(s,'x')))):
        for s in range(1440):
            b=d[s*512:(s+1)*512]
            if b.count(b[0])==512: continue
            for off in (0,256):
                pre=b[off:off+32]
                if pre.count(pre[0])==32: continue
                pos=R.find(pre)
                if pos>=0: cnt[pos//0x4000][lab(s)]+=1; break
    print('=====',j)
    for n in range(32):
        seg=R[n*0x4000:(n+1)*0x4000]; nz=sum(1 for b in seg if b)/0x4000*100
        c=cnt.get(n,{}); top=' '.join(f'{k}:{v}' for k,v in sorted(c.items(),key=lambda x:-x[1])[:5])
        print(f'{n:02X} nz{nz:5.1f}% {top}')
for j,dn,mi in (('S2_st_midi',2,1),('S2_st_fm',2,0),('S2_u5_midi',4,1),('S2_u5_fm',4,0)): run(j,dn,mi)
