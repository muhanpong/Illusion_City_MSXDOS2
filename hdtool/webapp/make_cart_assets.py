#!/usr/bin/env python3
"""make_cart_assets.py - adds the cartridge part to assets.json (no game data needed):
the 16KB boot block of hdtool/cart/cart.asm for each mapper, assembled with a zero-filled FRAY.DOS of the
release's size (the page puts disk 1's FRAY.DOS at `frayOff`), plus the ROM layout and patch G1 from mkcart.py.
usage: make_cart_assets.py"""
import base64, json, os, re, shutil, subprocess, sys, tempfile
here = os.path.dirname(os.path.abspath(__file__))
cart = os.path.join(here, '..', 'cart')
sys.path.insert(0, cart)
import mkcart

FRAYLEN = 3234          # FRAY.DOS of the supported release (disk 1)

out = {'frayLen': FRAYLEN, 'data': mkcart.DATA, 'font': mkcart.FONT, 'fontSize': mkcart.FONTSIZE,
       'save': mkcart.SAVE, 'saveFirst': mkcart.SAVEFIRST, 'slots': mkcart.SLOTS, 'group': mkcart.GROUP,
       'nsave': mkcart.NSAVE, 'tblLo': mkcart.TBLLO, 'tblHi': mkcart.TBLHI, 'dataEnd': mkcart.DATAEND,
       'romSize': mkcart.ROMSIZE, 'file9Sec': mkcart.FILE9_SEC, 'file9Base': mkcart.FILE9_BASE,
       'g1': {'sector': mkcart.G1_SEC, 'offset': mkcart.G1_OFF, 'orig': [o.hex() for o in mkcart.G1_ORIG], 'new': mkcart.G1_NEW.hex()},
       'g2': {'sector': mkcart.G2_SEC, 'offset': mkcart.G2_OFF, 'orig': [o.hex() for o in mkcart.G2_ORIG], 'new': mkcart.G2_NEW.hex()},
       'mappers': []}
with tempfile.TemporaryDirectory() as tmp:
    shutil.copy(os.path.join(cart, 'cart.asm'), tmp)
    os.makedirs(os.path.join(tmp, 'zx0'), exist_ok=True)
    shutil.copy(os.path.join(cart, 'zx0', 'dzx0_standard.asm'), os.path.join(tmp, 'zx0'))
    open(os.path.join(tmp, 'fray.dos'), 'wb').write(bytes(FRAYLEN))
    for mapper, tag in mkcart.MAPPERS.items():
        r = subprocess.run([mkcart.SJASM, f'-DMAPPER={mapper}', '--nologo', '--msg=war', '--sym=cart.sym', 'cart.asm'],
                           cwd=tmp, capture_output=True, text=True)
        if r.returncode:
            sys.exit(r.stdout + r.stderr)
        boot = open(os.path.join(tmp, 'cart.bin'), 'rb').read()
        assert len(boot) == 0x4000
        sym = open(os.path.join(tmp, 'cart.sym')).read()
        fray = int(re.search(r'^fray:\s+EQU\s+0x([0-9A-Fa-f]+)', sym, re.M).group(1), 16) - 0x4000
        syms = {m.group(1): int(m.group(2), 16) for m in re.finditer(r'^(\w+):\s+EQU\s+0x([0-9A-Fa-f]+)', sym, re.M)}
        ui = [{'addr': a, 'orig': o.hex(), 'new': n.hex()} for a, (o, n) in sorted(mkcart.ui_patches(syms).items())]
        assert out.setdefault('ui', ui) == ui, 'page-3 UI addresses differ between mappers'
        assert boot[fray:fray + FRAYLEN] == bytes(FRAYLEN)
        out['mappers'].append({'tag': tag, 'name': {'YAMA': 'Yamanooto', 'A16X': 'ASCII16-X'}[tag], 'fileSize': mkcart.FILESIZE[tag],
                               'boot': base64.b64encode(boot).decode(), 'frayOff': fray})
path = os.path.join(here, 'assets.json')
assets = json.load(open(path))
assets['cart'] = out
json.dump(assets, open(path, 'w'))
print('assets.json: cart part written', [(m['tag'], hex(m['frayOff'])) for m in out['mappers']])
