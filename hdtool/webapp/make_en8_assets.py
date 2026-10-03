#!/usr/bin/env python3
"""make_en8_assets.py - adds the English 8-disc release (MSX Translations) to assets.json (needs the English disks once):
  en8      launcher (ICITY.COM assembled with -DEN8 and the release's chunk tables), the patch table (mkdos2/patches_en8.py),
           the expected chunk start tables and the DIST_README_EN8.txt text
  cartEn8  the 16KB boot block of hdtool/cart/cart.asm (-DEN8) per mapper, assembled with a zero-filled 4096-byte "FRAY.DOS"
           (the page puts disk 1's sectors 0Bh-12h there), the ROM layout and patches P1-P6 (no G1/G2, no font)
usage: SJASM=/path/to/sjasmplus make_en8_assets.py <dir with the eight English .dsk (D1.dsk.. or the file-hunter names) and a user disk (DU.dsk; any, e.g. all zeros)>"""
import base64, json, os, re, shutil, subprocess, sys, tempfile
here = os.path.dirname(os.path.abspath(__file__))
mk = os.path.join(here, '..', 'mkdos2'); cart = os.path.join(here, '..', 'cart')
sys.path.insert(0, mk); sys.path.insert(0, cart)
import patches_en8, mkcart
SJASM = os.environ.get('SJASM') or mkcart.SJASM
disks = sys.argv[1]
FRAYLEN = 4096
path = os.path.join(here, 'assets.json')
assets = json.load(open(path))
with tempfile.TemporaryDirectory() as tmp:
    # launcher + chunk tables
    ref = os.path.join(tmp, 'ref'); work = os.path.join(tmp, 'mk')
    shutil.copytree(mk, work, ignore=shutil.ignore_patterns('test', '__pycache__', '*.lst', '*.COM'))
    r = subprocess.run([sys.executable, os.path.join(work, 'mkdos2.py'), disks, ref], capture_output=True, text=True)
    if r.returncode: sys.exit(r.stdout + r.stderr)
    m = json.load(open(os.path.join(ref, 'manifest.json')))
    assert m['release'] == 'en8', 'these are not the English 8-disc disks'
    r = subprocess.run([SJASM, '-DEN8', '--nologo', '-I' + ref, 'icity.asm'], cwd=work, capture_output=True, text=True)
    if r.returncode: sys.exit(r.stdout + r.stderr)
    com = open(os.path.join(work, 'ICITY.COM'), 'rb').read()
    pl = [{'id': p['id'], 'disk': p['disk'], 'sector': p['sector'], 'offset': p['offset'], 'orig': p['orig'].hex(), 'new': p['new'].hex(), 'font': False}
          for p in patches_en8.get_patches(True)]
    exp = {k[1:]: [c['start'] for c in v['chunks']] for k, v in m['disks'].items()}
    assets['en8'] = {'com': base64.b64encode(com).decode(), 'patches': pl, 'expected': exp,
                     'readme': open(os.path.join(mk, 'DIST_README_EN8.txt'), encoding='utf-8').read()}
    # cartridge boot blocks
    out = {'frayLen': FRAYLEN, 'data': mkcart.DATA, 'font': mkcart.FONT, 'fontSize': mkcart.FONTSIZE, 'save': mkcart.SAVE, 'saveFirst': mkcart.SAVEFIRST,
           'slots': mkcart.SLOTS, 'group': mkcart.GROUP, 'nsave': mkcart.NSAVE, 'tblLo': mkcart.TBLLO, 'tblHi': mkcart.TBLHI, 'dataEnd': mkcart.DATAEND,
           'romSize': mkcart.ROMSIZE, 'file9Sec': mkcart.FILE9_SEC, 'file9Base': mkcart.FILE9_BASE, 'mappers': []}
    ct = os.path.join(tmp, 'cart'); os.makedirs(os.path.join(ct, 'zx0'))
    shutil.copy(os.path.join(cart, 'cart.asm'), ct)
    shutil.copy(os.path.join(cart, 'zx0', 'dzx0_standard.asm'), os.path.join(ct, 'zx0'))
    open(os.path.join(ct, 'fray.dos'), 'wb').write(bytes(FRAYLEN))
    for mapper, tag in mkcart.MAPPERS.items():
        r = subprocess.run([SJASM, f'-DMAPPER={mapper}', '-DEN8=1', '--nologo', '--msg=war', '--sym=cart.sym', 'cart.asm'], cwd=ct, capture_output=True, text=True)
        if r.returncode: sys.exit(r.stdout + r.stderr)
        boot = open(os.path.join(ct, 'cart.bin'), 'rb').read()
        assert len(boot) == 0x4000
        sym = open(os.path.join(ct, 'cart.sym')).read()
        fray = int(re.search(r'^fray:\s+EQU\s+0x([0-9A-Fa-f]+)', sym, re.M).group(1), 16) - 0x4000
        syms = {mm.group(1): int(mm.group(2), 16) for mm in re.finditer(r'^(\w+):\s+EQU\s+0x([0-9A-Fa-f]+)', sym, re.M)}
        ui = [{'addr': a, 'orig': o.hex(), 'new': n.hex()} for a, (o, n) in sorted(mkcart.ui_patches(syms).items())]
        assert out.setdefault('ui', ui) == ui, 'page-3 UI addresses differ between mappers'
        assert boot[fray:fray + FRAYLEN] == bytes(FRAYLEN)
        out['mappers'].append({'tag': tag, 'name': {'YAMA': 'Yamanooto', 'A16X': 'ASCII16-X'}[tag], 'fileSize': mkcart.FILESIZE[tag],
                               'boot': base64.b64encode(boot).decode(), 'frayOff': fray})
    assets['cartEn8'] = out
json.dump(assets, open(path, 'w'))
print('assets.json: en8 + cartEn8 written', len(assets['en8']['com']), [(x['tag'], hex(x['frayOff'])) for x in out['mappers']])
