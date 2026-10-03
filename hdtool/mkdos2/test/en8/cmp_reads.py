import sys
def rd(p): return [tuple(l.split()[1:]) for l in open(p) if len(l.split())==4]
f,d=sys.argv[1],sys.argv[2]
a=rd(f)[2:]; b=rd(d)
n=min(len(a),len(b))
bad=[i for i in range(n) if a[i]!=b[i]]
print(f"{f.split('/')[0]}: floppy {len(a)} dos2 {len(b)} compared {n} mismatches {len(bad)}", [(i,a[i],b[i]) for i in bad[:3]])
