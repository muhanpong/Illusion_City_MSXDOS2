import sys, glob, os, re
sys.path.insert(0,'.')
from segcalls import chain_before
for a in sys.argv[1:]:
    t=int(a,16); lo,hi=t&0xff,t>>8
    print(f"### callers of {t:04X}")
    for f in sorted(glob.glob('bin/*.bin'))+['bin/FRAY.DOS']:
        d=open(f,'rb').read()
        for m in re.finditer(bytes([0xcd])+bytes([lo,hi])+b'|'+bytes([0xc3,lo,hi]),d):
            ch=chain_before(d,m.start(),30)
            print(f"  {os.path.basename(f)} +{m.start():05X}: "+" ; ".join(x for _,x in ch[-6:]))
