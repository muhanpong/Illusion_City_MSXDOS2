// node test_en8.js <dir with the 8 English .dsk> <user disk> <mkdos2 out tree (dir containing ICITY/)> <ICITY.COM built with -DEN8 for that tree> <mkcart out dir (ICITY_YAMA.rom, ICITY_A16X.rom)>
// core.js on the English 8-disc release must equal hdtool/mkdos2 (every chunk/save file, the launcher) and hdtool/cart/mkcart.py (both ROMs).
const fs = require('fs'), zlib = require('zlib');
require('./core.js');
const [dir, userf, tree, comf, romdir] = process.argv.slice(2);
const A = JSON.parse(fs.readFileSync(__dirname + '/assets.json', 'utf8'));
const rd = p => new Uint8Array(fs.readFileSync(p));
const inflate = async raw => new Uint8Array(zlib.inflateRawSync(Buffer.from(raw)));
const base = async () => { const it = fs.readdirSync(dir).map(n => ({ name: n, data: rd(dir + '/' + n) })); it.push({ name: 'userdisk.DSK', data: rd(userf) }); return ICITY.classify(it, inflate); };
let bad = 0; const ok = (c, m) => { console.log((c ? 'PASS ' : 'FAIL ') + m); if (!c) bad++; };
const err = (f, re) => { try { f(); return 'no error'; } catch (e) { return re.test(e.message) || e.message; } };
(async () => {
  let cls = await base();
  ok(cls.release === 'en8' && Object.keys(cls.disks).length === 8 && cls.user, 'English release detected, 8 disks + user disk');
  // DOS2 launcher + chunk files
  const r = ICITY.build({ assets: A, cls, readme: true, useFont: true, log: m => console.log(' ', m) });
  const files = ICITY.flatten(r.rootFiles, ''); const byPath = new Map(files.map(f => [f.path, f.data]));
  ok(!r.fontOn && !byPath.has('ICITY/FONT.BIN'), 'no font in the English build');
  ok(Buffer.compare(Buffer.from(byPath.get('ICITY.COM')), fs.readFileSync(comf)) === 0, 'ICITY.COM identical to the -DEN8 build');
  let n = 0, diff = 0;
  const walk = (d, pre) => { for (const e of fs.readdirSync(d, { withFileTypes: true })) { const p = pre + e.name; if (e.isDirectory()) walk(d + '/' + e.name, p + '/'); else if (/^ICITY\//.test(p)) { n++; const w = byPath.get(p); if (!w || Buffer.compare(Buffer.from(w), fs.readFileSync(d + '/' + e.name)) !== 0) { diff++; console.log('  differs/missing:', p); } } } };
  walk(tree, '');
  ok(n > 1000 && diff === 0 && files.filter(f => /^ICITY\//.test(f.path)).length === n, n + ' chunk/save files identical to mkdos2.py (' + diff + ' differ)');
  ok(r.applied.join() === 'L1,L4,K1,INIT,K2,M1,M2,M3,P1,P2,P3,P4,P5,P6', 'patches: ' + r.applied.join());
  const img = ICITY.makeImage(r.rootFiles, r.boot, 'ICITYDOS2', new Date()); ok(img.used < img.clusters, 'image fits (' + img.used + '/' + img.clusters + ')');
  ok(/MSX Translations/.test(Buffer.from(byPath.get('README.TXT')).toString()), 'README credits MSX Translations');
  // cartridge ROMs
  const roms = ICITY.buildCart({ assets: A, cls, log: m => console.log(' ', m) });
  for (const x of roms) ok(Buffer.compare(fs.readFileSync(romdir + '/ICITY_' + x.tag + '.rom'), Buffer.from(x.rom)) === 0, x.tag + ' ROM identical to mkcart.py');
  // blank saves / errors
  const rb = ICITY.buildCart({ assets: A, cls, keepSaves: false })[0].rom, C = A.cartEn8;
  let z = true; for (let k = 0; k < 8; k++) { const slot = C.slots + k, g = Math.floor(slot / C.group), p = slot % C.group, o = C.save + g * 0x10000 + (p >> 3) * 0x4000 + (p & 7) * 0x400; if (rb.subarray(o, o + 1024).some(b => b)) z = false; }
  ok(z, 'blank saves: user slots all zero');
  ok(err(() => ICITY.buildFdd({ assets: A, cls }), /only for the Korean release/) === true, 'floppy version refused for the English release');
  let c2 = await base(); const d1 = c2.disks[1].data.slice(); d1[11 * 512 + 20] ^= 0xFF; c2.disks[1] = { name: 'x', data: d1 };
  ok(err(() => ICITY.build({ assets: A, cls: c2 }), /patch L1|do not match/) === true, 'DOS2: changed patch bytes -> error');
  c2 = await base(); const d1b = c2.disks[1].data.slice(); const pc = C.ui[0]; d1b[C.file9Sec * 512 + pc.addr - C.file9Base] ^= 1; c2.disks[1] = { name: 'x', data: d1b };
  ok(err(() => ICITY.buildCart({ assets: A, cls: c2 }), /save-list patch/) === true, 'cartridge: changed save-list bytes -> error');
  const sl = ICITY.saveSlots(cls.disks[1].data, cls.user.data); ok(sl.length === 8 && sl.every(s => s.valid === (s.lv !== null)), 'save slot list reads (scene codes)');
  console.log(bad ? bad + ' FAILED' : 'all passed'); process.exit(bad ? 1 : 0);
})().catch(e => { console.error('ERROR:', e.message); process.exit(1); });
