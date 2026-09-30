// node test_fdd.js <zip or disk dir> <KANJI.rom> <mkfdd.py out dir> : core.js buildFdd must equal hdtool/fdd/mkfdd.py
const fs = require('fs'), zlib = require('zlib');
require('./core.js');
const [src, fontf, refdir] = process.argv.slice(2);
const A = JSON.parse(fs.readFileSync(__dirname + '/assets.json', 'utf8'));
const items = [];
if (fs.statSync(src).isDirectory()) { for (const n of fs.readdirSync(src)) items.push({ name: n, data: new Uint8Array(fs.readFileSync(src + '/' + n)) }); }
else items.push({ name: src.split('/').pop(), data: new Uint8Array(fs.readFileSync(src)) });
items.push({ name: 'KANJI.rom', data: new Uint8Array(fs.readFileSync(fontf)) });
(async () => {
  const cls = await ICITY.classify(items, async raw => new Uint8Array(zlib.inflateRawSync(Buffer.from(raw))));
  const out = ICITY.buildFdd({ assets: A, cls, log: m => console.log(' ', m) });
  let bad = 0;
  for (const d of out) {
    const eq = Buffer.compare(fs.readFileSync(refdir + '/D' + d.n + '.dsk'), Buffer.from(d.data)) === 0;
    if (!eq || d.n === 1) console.log('D' + d.n, eq ? 'identical to mkfdd.py' : 'DIFFERS');
    if (!eq) bad++;
  }
  const t = (name, f) => { try { const r = f(); if (r === true) console.log('PASS', name); else { console.log('FAIL', name, r); bad++; } } catch (e) { console.log('FAIL', name, e.message); bad++; } };
  const err = (f, re) => { try { f(); return 'no error'; } catch (e) { return re.test(e.message) || e.message; } };
  const with1 = f => { const d1 = cls.disks[1].data.slice(); f(d1); return Object.assign({}, cls, { disks: Object.assign({}, cls.disks, { 1: { name: 'd1', data: d1 } }) }); };
  t('no font -> error', () => err(() => ICITY.buildFdd({ assets: A, cls: Object.assign({}, cls, { font: null }) }), /needs the font/));
  t('missing disk 5 -> error', () => { const d = Object.assign({}, cls.disks); delete d[5]; return err(() => ICITY.buildFdd({ assets: A, cls: Object.assign({}, cls, { disks: d }) }), /game disk 5/); });
  t('file 7 bytes differ -> error', () => err(() => ICITY.buildFdd({ assets: A, cls: with1(d => { d[82 * 512 + 0x29B9] ^= 1; }) }), /file 7 2AB9h/));
  t('font area not empty -> error', () => err(() => ICITY.buildFdd({ assets: A, cls: with1(d => { d[0x560 * 512] ^= 1; }) }), /not empty/));
  t('input disk 1 not modified', () => ICITY.buildFdd({ assets: A, cls }) && cls.disks[1].data[82 * 512 + 0x29B9] === 0x7D);
  console.log(bad ? 'FAILED' : 'all passed');
  process.exit(bad ? 1 : 0);
})().catch(e => { console.error('ERROR:', e.message); process.exit(1); });
