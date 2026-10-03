import sys,zlib,struct
b=open(sys.argv[1]+'.bin','rb').read(); t=open(sys.argv[1]+'.txt').read().split('\n')
regs=list(map(int,t[0].split()[1:])); cols=t[1].split()[1:]
pal=[(int(c[0])*255//7,int(c[1])*255//7,int(c[2])*255//7) for c in cols]
page=(regs[2]>>5)&3; base=page*0x8000
W,H=256,212; rows=[]
for y in range(H):
    r=bytearray([0])
    for x in range(0,W,2):
        v=b[base+y*128+x//2]
        for n in (v>>4,v&15): r+=bytes(pal[n])
    rows.append(bytes(r))
def ch(k,d): c=struct.pack('>I',len(d))+k+d; return c+struct.pack('>I',zlib.crc32(k+d))
img=b'\x89PNG\r\n\x1a\n'+ch(b'IHDR',struct.pack('>IIBBBBB',W,H,8,2,0,0,0))+ch(b'IDAT',zlib.compress(b''.join(rows)))+ch(b'IEND',b'')
open(sys.argv[2],'wb').write(img)
