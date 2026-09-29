// node test_cart.js <zip or disk dir> <userdisk> <KANJI.rom> <mkcart out dir> : core.js buildCart must equal hdtool/cart/mkcart.py
const fs = require('fs'), zlib = require('zlib');
require('./core.js');
const [src, userf, fontf, refdir] = process.argv.slice(2);
const A = JSON.parse(fs.readFileSync(__dirname + '/assets.json', 'utf8'));
const items = [];
if (fs.statSync(src).isDirectory()) { for (const n of fs.readdirSync(src)) items.push({ name: n, data: new Uint8Array(fs.readFileSync(src + '/' + n)) }); }
else items.push({ name: src.split('/').pop(), data: new Uint8Array(fs.readFileSync(src)) });
items.push({ name: 'userdisk.DSK', data: new Uint8Array(fs.readFileSync(userf)) });
items.push({ name: 'KANJI.rom', data: new Uint8Array(fs.readFileSync(fontf)) });
(async () => {
  const cls = await ICITY.classify(items, async raw => new Uint8Array(zlib.inflateRawSync(Buffer.from(raw))));
  const roms = ICITY.buildCart({ assets: A, cls, log: m => console.log(' ', m) });
  let bad = 0;
  for (const r of roms) {
    const ref = fs.readFileSync(refdir + '/ICITY_' + r.tag + '.rom');
    const eq = Buffer.compare(ref, Buffer.from(r.rom)) === 0;
    console.log(r.tag, r.rom.length, eq ? 'identical to mkcart.py' : 'DIFFERS');
    if (!eq) bad++;
  }
  // edge cases
  const C = A.cart, t = (name, f) => { try { const r = f(); if (r === true) console.log('PASS', name); else { console.log('FAIL', name, r); bad++; } } catch (e) { console.log('FAIL', name, e.message); bad++; } };
  const err = (f, re) => { try { f(); return 'no error'; } catch (e) { return re.test(e.message) || e.message; } };
  t('no font -> error', () => err(() => ICITY.buildCart({ assets: A, cls: Object.assign({}, cls, { font: null }) }), /needs the font/));
  t('missing disk 3 -> error', () => { const d = Object.assign({}, cls.disks); delete d[3]; return err(() => ICITY.buildCart({ assets: A, cls: Object.assign({}, cls, { disks: d }) }), /game disk 3/); });
  t('blank saves -> user slots all zero', () => { const r = ICITY.buildCart({ assets: A, cls, keepSaves: false })[0].rom;
    for (let n = 0; n < 8; n++) { const o = C.save + (8 + n) * C.saveSlot; if (r.subarray(o, o + 1024).some(b => b)) return 'slot ' + n; } return true; });
  t('G1 bytes differ -> error', () => { const d1 = cls.disks[1].data.slice(); d1[C.g1.sector * 512 + C.g1.offset + 9] ^= 1;
    const d = Object.assign({}, cls.disks, { 1: { name: 'd1', data: d1 } }); return err(() => ICITY.buildCart({ assets: A, cls: Object.assign({}, cls, { disks: d }) }), /patch G1/); });
  t('input disk 1 not modified', () => ICITY.buildCart({ assets: A, cls }) && cls.disks[1].data[C.g1.sector * 512 + C.g1.offset] === 0x7D);
  console.log(bad ? 'FAILED' : 'all passed');
  process.exit(bad ? 1 : 0);
})().catch(e => { console.error('ERROR:', e.message); process.exit(1); });
