// node test_ja.js <dir with the 8 Japanese .dsk> <user disk> <font or -> <mkdos2 out tree (dir containing ICITY/)> <ICITY.COM for that tree> <mkcart out dir>
// core.js on the Japanese original must equal hdtool/mkdos2 (every chunk/save file, the launcher) and hdtool/cart/mkcart.py
// (both ROMs and the 8MB ASCII16-X file of --pad8), with a Kanji ROM file as the font or without one ("-": the machine's Kanji ROM).
const fs = require('fs'), zlib = require('zlib');
require('./core.js');
const [dir, userf, fontf, tree, comf, romdir] = process.argv.slice(2);
const A = JSON.parse(fs.readFileSync(__dirname + '/assets.json', 'utf8'));
const rd = p => new Uint8Array(fs.readFileSync(p));
const inflate = async raw => new Uint8Array(zlib.inflateRawSync(Buffer.from(raw)));
const font = fontf && fontf !== '-';
let bad = 0; const ok = (c, m) => { console.log((c ? 'PASS ' : 'FAIL ') + m); if (!c) bad++; };
const err = (f, re) => { try { f(); return 'no error'; } catch (e) { return re.test(e.message) || e.message; } };
(async () => {
  const it = fs.readdirSync(dir).filter(n => /\.dsk$/i.test(n)).map(n => ({ name: n, data: rd(dir + '/' + n) }));
  it.push({ name: 'userdisk.DSK', data: rd(userf) }); if (font) it.push({ name: 'KANJI.rom', data: rd(fontf) });
  const cls = await ICITY.classify(it, inflate);
  ok(cls.release === 'ja' && Object.keys(cls.disks).length === 8 && cls.user && !!cls.font === font, 'Japanese release detected, 8 disks + user disk' + (font ? ' + font' : ', no font'));
  // DOS2 launcher + chunk files (+ FONT.BIN)
  const r = ICITY.build({ assets: A, cls, readme: true, useFont: font, log: m => console.log(' ', m) });
  const files = ICITY.flatten(r.rootFiles, ''); const byPath = new Map(files.map(f => [f.path, f.data]));
  ok(r.fontOn === font && byPath.has('ICITY/FONT.BIN') === font, font ? 'FONT.BIN shipped, G1/G2 applied' : 'no FONT.BIN, no G1/G2');
  ok(Buffer.compare(Buffer.from(byPath.get('ICITY.COM')), fs.readFileSync(comf)) === 0, 'ICITY.COM identical to the build.sh launcher');
  let n = 0, diff = 0;
  const walk = (d, pre) => { for (const e of fs.readdirSync(d, { withFileTypes: true })) { const p = pre + e.name; if (e.isDirectory()) walk(d + '/' + e.name, p + '/'); else if (/^ICITY\//.test(p)) { n++; const w = byPath.get(p); if (!w || Buffer.compare(Buffer.from(w), fs.readFileSync(d + '/' + e.name)) !== 0) { diff++; console.log('  differs/missing:', p); } } } };
  walk(tree, '');
  ok(n > 1000 && diff === 0 && files.filter(f => /^ICITY\//.test(f.path)).length === n, n + ' chunk/save files identical to mkdos2.py (' + diff + ' differ)');
  ok(r.applied.join() === 'L1,L4,K1,INIT,K2,M1,M2,M3,P1,P2,P3,P4,P5,P6' + (font ? ',G1,G2' : ''), 'patches: ' + r.applied.join());
  // cartridge ROMs (4MB each + the 8MB ASCII16-X file)
  const roms = ICITY.buildCart({ assets: A, cls, pad8: true, log: m => console.log(' ', m) });
  for (const x of roms) ok(Buffer.compare(fs.readFileSync(romdir + '/ICITY_' + x.tag + '.rom'), Buffer.from(x.rom)) === 0, x.tag + ' ROM identical to mkcart.py');
  const yama = roms.find(x => x.tag === 'YAMA').rom, F = A.cart.font;
  ok(font ? yama.subarray(F, F + 262144).some(b => b !== 0xFF) : yama.subarray(F, F + 262144).every(b => b === 0xFF), font ? 'font area holds the font' : 'font area left 0FFh');
  ok(err(() => ICITY.buildFdd({ assets: A, cls }), /only for the Korean release/) === true, 'floppy version refused for the Japanese release');
  const sl = ICITY.saveSlots(cls.disks[1].data, cls.user.data); ok(sl.length === 8 && sl.filter(s => s.valid).every(s => /[぀-ヿ一-鿿]/.test(s.place)), 'save slot places read as Japanese');
  console.log(bad ? bad + ' FAILED' : 'all passed'); process.exit(bad ? 1 : 0);
})().catch(e => { console.error('ERROR:', e.message); process.exit(1); });
