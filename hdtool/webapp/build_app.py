#!/usr/bin/env python3
"""build_app.py - inline core.js and assets.json into one HTML file (icity_dsk_maker.html).
assets.json is produced from hdtool/mkdos2 (launcher, boot sector, patches, expected chunk tables): see make_assets.py."""
import json, os, sys
here = os.path.dirname(os.path.abspath(__file__))
tpl = open(os.path.join(here, 'app.html.tpl'), encoding='utf-8').read()
core = open(os.path.join(here, 'core.js'), encoding='utf-8').read()
assets = open(os.path.join(here, 'assets.json'), encoding='utf-8').read()
assert '</script' not in core and '</script' not in assets
out = tpl.replace('/*ASSETS*/', assets).replace('/*CORE*/', core)
dst = sys.argv[1] if len(sys.argv) > 1 else os.path.join(here, 'icity_dsk_maker.html')
open(dst, 'w', encoding='utf-8').write(out)
print(dst, len(out.encode('utf-8')), 'bytes')
