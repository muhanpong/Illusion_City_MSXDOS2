#!/usr/bin/env python3
"""songscan.py - which MIDI songs each Illusion City disk can play: a static scan of the game data (no emulator).
usage: songscan.py <dir with D1.dsk .. D8.dsk>   (the original 720KB images, any disk order by name)

Song numbers are the 0-based index into the 37-entry song table (file 4 builds it at CD00h; sector, count on disk 1).
The game keeps the wanted song in CA48h (1-based: 0 = none, file 7 5050h) and plays CA48h-1 (file 7 02E4h -> module 4012h).
Where the numbers come from (found with openMSX traces, see SONGSCAN.md):
  INF   each disk's file 6 ("INF"): 26-byte scene records after a 20h header, +24 = BGM (1-based), +25 = second
        channel (1-based, CA49h / file 7 505Dh); file 7 4D6Fh applies them when a scene is entered.
  EVT-B a scene's event chunk ("EVT" header; the INF record's chunk list): section 4 holds text-command scripts
        (file 9 7614h interpreter, command table 7BBCh; each command = letter [+count] + args, 'E'/'e' end);
        command 'B' + n is copied to F7EDh/F7EEh and file 9 7842h plays n when the event starts.
  BC-0F EVT section 5 / disk 1 file 11: bytecode (file 9 85FAh, handler table 7E21h); statement c8 0f <c1 n> sets
        song n (1-based) through file 9 8009h. Only literal operands are recognised.
  const disk 1: file 5 (title/opening) `ld a,n / call 981Ch`, file 14 (ending) `ld a,n / call 9C55h` (1-based).
  engine file 9 47F8h sets song 0 itself.
Not covered: operands computed at run time (none seen), the FM sound driver (separate data)."""
import sys, re, os
CMD={0x53:(1,2),0x4D:(1,10),0x41:(1,2),0x50:(2,3),0x4C:(0,5),0x6D:(0,4),0x54:(0,3),0x47:(0,2),0x67:(0,1),0x70:(0,1),0x42:(0,1),0x62:(0,1),0x66:(0,1),0x77:(0,1),0x43:(0,3)}
SONGTAB="014A:8 0152:8 015A:10 0164:8 016C:13 0179:13 0186:8 018E:12 019A:7 01A1:20 01B5:8 01BD:11 0000:0 01C8:9 01D1:6 01D7:8 01DF:6 01E5:5 01EA:4 0000:0 01EE:8 01F6:23 020D:13 021A:13 0227:7 022E:7 0235:10 023F:13 024C:13 0259:11 0264:18 0276:11 0281:16 0291:18 02A3:14 02B1:22 02C7:2".split()
SIZES=[int(x.split(':')[1]) for x in SONGTAB]
def disk(n): return open(os.path.join(sys.argv[1], f'D{n}.dsk'),'rb').read()
def filetab(d):
    t=d[11*512:11*512+30]; return [(t[i],t[i+1]) for i in range(0,30,2)]
def inf_records(d):
    s,c=filetab(d)[6]; inf=d[s*512:(s+c)*512]
    if inf[:4]!=b'INF\0': return []
    ln=[inf[6+2*i]|inf[7+2*i]<<8 for i in range(5)]
    if ln[0]==0: return []
    return [inf[o:o+26] for o in range(0x20,0x20+ln[0],26)]
def evt(chunk):
    if chunk[:4]!=b'EVT\0': return None
    lens=[chunk[6+2*i]|chunk[7+2*i]<<8 for i in range(5)]
    n=chunk[0x15]|chunk[0x16]<<8          # number of scripts (u16 at 15h)
    secs=[]; o=0x20
    for l in lens: secs.append((o,l)); o+=l
    return lens,secs,n
def parse_scripts(sec, n):
    """section 4: n u16 offsets, scripts at 2n+offset, commands from the 7BBC table, 'E'/'e' separators."""
    if 2*n>len(sec): return set(),0,1
    base=2*n; ents=sorted(set(base+(sec[2*i]|sec[2*i+1]<<8) for i in range(n)))
    songs=set(); bad=0; ok=0; p=base
    while p<len(sec):
        c=sec[p]
        if c in (0x45,0x65): p+=1; continue
        if c not in CMD:
            bad+=1; nxt=[e for e in ents if e>p]
            if not nxt: break
            p=nxt[0]; continue
        idx,size=CMD[c]
        ln = 1+idx+size*sec[p+idx] if idx else 1+size
        if c==0x42: songs.add(sec[p+1])
        p+=ln; ok+=1
    return songs, ok, bad
def scan():
    use={}   # song index (0-based, as played) -> {disk: set(sources)}
    def add(song, n, src):
        if 0<=song<37: use.setdefault(song,{}).setdefault(n,set()).add(src)
    stats={}
    for n in range(1,9):
        d=disk(n); recs=inf_records(d); seen=set(); ok=bad=0; nevt=0
        for r in recs:
            if r[24]: add(r[24]-1, n, 'INF')
            if r[25]: add(r[25]-1, n, 'INF2')
            for k in range(7):
                a=r[3+3*k]|r[4+3*k]<<8; cnt=r[5+3*k]
                if not cnt or a in seen: continue
                seen.add(a); chunk=d[a*512:(a+cnt)*512]; e=evt(chunk)
                if not e: continue
                nevt+=1; lens,secs,cnt_=e
                so,sl=secs[3]; s,o,b=parse_scripts(chunk[so:so+sl], cnt_); ok+=o; bad+=b
                for x in s: add(x, n, 'EVT-B')
                so,sl=secs[4]
                for m in re.finditer(rb'\xc8\x0f\xc1(.)', chunk[so:so+sl], re.S): add(m.group(1)[0]-1, n, 'BC-0F')
        stats[n]=(len(recs), nevt, ok, bad)
    # disk 1: file 11 bytecode, file 5 (opening) and file 14 (ending) constants
    d=disk(1); tab=filetab(d)
    f=lambda i: d[tab[i][0]*512:(tab[i][0]+tab[i][1])*512]
    for m in re.finditer(rb'\xc8\x0f\xc1(.)', f(11), re.S): add(m.group(1)[0]-1, 1, 'BC-0F')
    for i,setfn in ((5,0x981c),(14,0x9c55)):
        b=f(i)
        for m in re.finditer(bytes([0x3e])+b'(.)'+bytes([0xcd,setfn&0xff,setfn>>8]), b, re.S): add(m.group(1)[0]-1, 1, 'const')
    for n in range(1,9): add(0, n, 'engine')   # file 9 47F8: D8F5=1 -> song 0
    return use, stats
if __name__=='__main__':
    use,stats=scan()
    print("disk: INF records, EVT chunks, script commands ok/bad")
    for n,(r,e,o,b) in stats.items(): print(f"  {n}: {r} {e} {o}/{b}")
    print("\nsong  sectors  disks (sources)")
    for s in range(37):
        u=use.get(s,{})
        print(f"  {s:2d}  {SIZES[s]:3d}   " + '  '.join(f"{n}:{'+'.join(sorted(v))}" for n,v in sorted(u.items())))
    only1=[s for s in range(37) if SIZES[s] and set(use.get(s,{}))<= {1}]
    print("\nused only with disk 1 (or never):", only1, "sectors", sum(SIZES[s] for s in only1))
    for n in range(2,9):
        ss=[s for s in range(37) if n in use.get(s,{})]
        print(f"disk {n}: songs {ss} sectors {sum(SIZES[s] for s in ss)}")
