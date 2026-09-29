#!/usr/bin/env python3
"""make_assets.py - writes assets.json for the web app from a reference build (needs the game disks once):
launcher (ICITY.COM built by hdtool/mkdos2), boot sector (from an image made by mkhd.py), the patch table
(mkdos2/patches.py) and the chunk start tables the launcher was compiled with.
usage: make_assets.py <disk dir> <ICITY.COM> <boot sector source .dsk> [work dir]"""
import sys, os, json, base64, subprocess, tempfile
here = os.path.dirname(os.path.abspath(__file__)); mk = os.path.join(here, '..', 'mkdos2')
sys.path.insert(0, mk)
import patches
disks, com, bootimg = sys.argv[1:4]
work = sys.argv[4] if len(sys.argv) > 4 else tempfile.mkdtemp()
pl = [{'id': p['id'], 'disk': p['disk'], 'sector': p['sector'], 'offset': p['offset'], 'orig': p['orig'].hex(), 'new': p['new'].hex(), 'font': p['id'] == 'G1'} for p in patches.get_patches(True, True)]
out = os.path.join(work, 'ref')
subprocess.run([sys.executable, os.path.join(mk, 'mkdos2.py'), disks, out], check=True, capture_output=True)
m = json.load(open(os.path.join(out, 'manifest.json')))
exp = {k[1:]: [c['start'] for c in v['chunks']] for k, v in m['disks'].items()}
json.dump({'com': base64.b64encode(open(com, 'rb').read()).decode(), 'boot': base64.b64encode(open(bootimg, 'rb').read(512)).decode(),
           'patches': pl, 'expected': exp, 'readme': open(os.path.join(mk, 'DIST_README.txt'), encoding='utf-8').read()}, open(os.path.join(here, 'assets.json'), 'w'))
print('assets.json written')
