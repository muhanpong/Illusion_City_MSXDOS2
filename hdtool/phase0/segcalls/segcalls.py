import glob, os, re, sys, collections
from z80dis import z80
TARGETS = {0xE030:'A', 0xE246:'A', 0xE25B:'A', 0xE02D:'IXH', 0xE224:'IXH'}
def dec(d, pc):
    try:
        x = z80.decode(d[pc:pc+6], pc)
        if x.len > 0: return x.len, z80.decoded2str(x)
    except Exception: pass
    return 1, 'db %02X' % d[pc]
def chain_before(d, site, back=24):
    # find an aligned decode run that lands exactly on `site`; prefer the longest
    best = None
    for st in range(max(0, site-back), site):
        pc, ins = st, []
        while pc < site:
            n, t = dec(d, pc); ins.append((pc, t)); pc += n
        if pc == site and not any(t.startswith('db') for _, t in ins):
            best = ins; break
    return best or []
def writes(reg, t):
    t = t.upper()
    if reg == 'A':
        return bool(re.match(r'(LD A,|POP AF|EX AF|XOR |OR |AND |SUB |ADD A|ADC A|SBC A|INC A|DEC A|NEG|CPL|RLCA|RRCA|RLA|RRA|IN A|EXX)', t))
    return bool(re.match(r'(LD IXH|LD IX,|POP IX|INC IXH|DEC IXH|LD IXH,|EX \(SP\),IX)', t))
if __name__ != "__main__": pass
def main():
    rows = []    
    files = sorted(glob.glob('bin/*.bin')) + ['bin/FRAY.DOS']
    for f in files:
        d = open(f, 'rb').read()
        for m in re.finditer(rb'[\xcd\xc3\xc4\xcc\xd4\xdc\xc2\xca\xd2\xda]([\x00-\xff])[\xe0\xe2]', d):
            tgt = m.group(1)[0] | (d[m.start()+2] << 8)
            if tgt not in TARGETS: continue
            reg = TARGETS[tgt]; site = m.start()
            ch = chain_before(d, site)
            setter = None
            for pc, t in reversed(ch):
                if writes(reg, t): setter = t; break
            # page (B) for E030
            page = None
            if reg == 'A':
                for pc, t in reversed(ch):
                    if t.upper().startswith('LD B,'): page = t[5:]; break
            if setter is None: kind = 'unknown'
            elif re.match(r'LD (A|IXH),(0x)?[0-9a-fA-F]+$', setter): kind = 'literal'
            elif re.match(r'LD IX,(0x)?[0-9a-fA-F]+$', setter): kind = 'literal'
            elif re.match(r'LD A,\((0x)?[0-9a-fA-F]+\)$', setter): kind = 'memory'
            else: kind = 'computed'
            ctx = ' ; '.join(t for _, t in ch[-5:])
            rows.append((os.path.basename(f), site, '%04X' % tgt, reg, kind, setter or '-', page or '-', ctx))
    cnt = collections.Counter(r[4] for r in rows)
    print("total call sites:", len(rows), dict(cnt))
    for r in rows:
        if r[4] != 'literal':
            print("%-22s +%05X %s %-3s %-8s set=[%s] B=%s | %s" % r)
    lits = sorted({r[5] for r in rows if r[4]=='literal'})
    print("literal setters:", lits)
    
if __name__=="__main__":
    main()
