#!/usr/bin/env python3
"""make_fdd_assets.py - adds the floppy part to assets.json (no game data needed): the assembled FRAY.DOS tail and
segment-1Fh code of hdtool/fdd/fdd.asm, its symbols, and the glyph list (hdtool/phase0/glyphscan/glyphset.json).
Rerun it and build_app.py whenever hdtool/fdd changes.
usage: make_fdd_assets.py"""
import base64, json, os, sys
here = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(here, '..', 'fdd'))
import mkfdd

glyphs = mkfdd.glyph_list()
A = mkfdd.assemble(len(glyphs))
out = {k: A[k] for k in ('blk', 'nglyph', 'nblk', 'fontsec', 'fontmax', 'seg1e', 'DATA', 'BUF', 'STUBLEN', 'init', 'g7', 'g14',
                         'n1imm', 'n2sec', 'n2imm')}
out['loader'] = base64.b64encode(A['loader']).decode()
out['code'] = base64.b64encode(A['code']).decode()
out['glyphs'] = glyphs
path = os.path.join(here, 'assets.json')
assets = json.load(open(path))
assets['fdd'] = out
json.dump(assets, open(path, 'w'))
print('assets.json: fdd part written', len(A['loader']), 'loader bytes,', len(A['code']), 'code bytes,', len(glyphs), 'glyphs')
