import sys
def rd(p): return [tuple(l.split()[1:4]) for l in open(p) if len(l.split())>=4 and l.split()[1] in ('2F','30')]
f,d=sys.argv[1],sys.argv[2]
skip=int(sys.argv[3]) if len(sys.argv)>3 else 2
a=rd(f)[skip:]; b=rd(d)
n=min(len(a),len(b))
bad=[i for i in range(n) if a[i]!=b[i]]
print(f"{d.split('/')[0]}: floppy {len(a)} cart {len(b)} compared {n} mismatches {len(bad)}", [(i,a[i],b[i]) for i in bad[:3]])
