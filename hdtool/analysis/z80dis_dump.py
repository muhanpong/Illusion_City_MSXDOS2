import sys
from z80dis import z80
data=open(sys.argv[1],'rb').read()
org=int(sys.argv[2],16); start=int(sys.argv[3],16) if len(sys.argv)>3 else 0
end=int(sys.argv[4],16) if len(sys.argv)>4 else len(data)
pc=start
while pc<end:
    try:
        d=z80.decode(data[pc:pc+6], org+pc)
        n=d.len if d.len>0 else 1
        txt=z80.decoded2str(d) if d.len>0 else 'db %02X'%data[pc]
    except Exception as e:
        n=1; txt='db %02X'%data[pc]
    hexs=' '.join('%02X'%b for b in data[pc:pc+n])
    asc=''.join(chr(b) if 32<=b<127 else '.' for b in data[pc:pc+n])
    print('%04X: %-18s %-28s %s'%(org+pc,hexs,txt,asc))
    pc+=n
