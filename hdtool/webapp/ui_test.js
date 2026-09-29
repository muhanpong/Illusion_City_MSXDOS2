// needs `npm i jsdom`; run: node ui_test.js icity_dsk_maker.html <zip> <userdisk> <KANJI.rom> <sys dir> <out dir> [cart]
// (cart: choose "카트리지 ROM" and download both ROMs instead of the DSK/ZIP)
// Runs the real page (icity_dsk_maker.html) in jsdom: drops the input files, presses the buttons, saves the downloads.
const { JSDOM } = require('jsdom'); const fs = require('fs'), zlib = require('zlib');
const [html, zipf, userf, fontf, sysdir, outdir, mode] = process.argv.slice(2);
(async () => {
  const dom = new JSDOM(fs.readFileSync(html, 'utf8'), { runScripts: 'dangerously', pretendToBeVisual: true, url: 'http://localhost/' });
  const w = dom.window;
  // browser APIs jsdom lacks
  w.TextEncoder = TextEncoder; w.TextDecoder = TextDecoder; w.Uint8Array = Uint8Array;
  w.DecompressionStream = undefined; // force our fallback path to be tested separately; inflate is injected below
  const saved = {};
  w.URL.createObjectURL = blob => { const id = 'blob:' + Math.random(); saved[id] = blob; return id; }; w.URL.revokeObjectURL = () => { };
  w.HTMLAnchorElement.prototype.click = function () { if (this.download) { saved['dl:' + this.download] = saved[this.href]; } };
  await new Promise(r => setTimeout(r, 200));
  const d = w.document;
  const mk = (name, path) => { const b = fs.readFileSync(path); const f = new w.File([b], name); f.arrayBuffer = async () => b.buffer.slice(b.byteOffset, b.byteOffset + b.length); return f; };
  const files = [mk('illucity_K.zip', zipf), mk('userdisk.DSK', userf), mk('KANJI.rom', fontf)];
  for (const n of fs.readdirSync(sysdir)) files.push(mk(n, sysdir + '/' + n));
  // zip inflate: jsdom has no DecompressionStream, so provide one backed by zlib for the test
  w.DecompressionStream = class { constructor() { let chunks = []; this.writable = new w.WritableStream ? null : null; } };
  // simpler: monkeypatch the page's inflate through Blob().stream() is not available; instead replace ICITY.classify's inflate by wrapping
  const orig = w.ICITY.classify; w.ICITY.classify = (items) => orig(items, async raw => new Uint8Array(zlib.inflateRawSync(Buffer.from(raw))));
  const ev = new w.Event('drop'); ev.dataTransfer = { files }; d.getElementById('drop').dispatchEvent(ev);
  await new Promise(r => setTimeout(r, 1500));
  const chips = Array.from(d.querySelectorAll('.chip')).map(c => c.textContent.replace(/\s+/g, ' '));
  console.log('chips:', chips.join(' | '));
  console.log('make disabled:', d.getElementById('make').disabled, 'dos row hidden:', d.getElementById('dosRow').hidden);
  if (mode === 'cart') {
    d.querySelector('.seg[data-opt="target"] button[data-v="cart"]').click();
    await new Promise(r => setTimeout(r, 1500));
    console.log('cart mode: dsk-only rows hidden:', Array.from(d.querySelectorAll('.dsk-only')).every(r => r.hidden), 'rom buttons shown:', !d.getElementById('dlYAMA').hidden && !d.getElementById('dlA16X').hidden, 'make disabled:', d.getElementById('make').disabled);
  } else d.querySelector('.seg[data-opt="autoexec"] button[data-v="on"]').click(); // options: autoexec on
  d.getElementById('make').click();
  await new Promise(r => setTimeout(r, 4000));
  console.log('msg:', d.getElementById('msg').textContent);
  console.log('log:', d.getElementById('log').textContent.trim().split('\n').join(' / '));
  const dl = mode === 'cart' ? ['dlYAMA', 'dlA16X'] : ['dlDsk', 'dlZip'];
  console.log('dl buttons enabled:', dl.map(id => !d.getElementById(id).disabled).join(' '));
  for (const id of dl) d.getElementById(id).click();
  await new Promise(r => setTimeout(r, 300));
  for (const k of Object.keys(saved)) if (k.startsWith('dl:')) { const blob = saved[k]; const buf = Buffer.from(await blob.arrayBuffer()); const fn = outdir + '/' + k.slice(3); fs.writeFileSync(fn, buf); console.log('saved', fn, buf.length); }
  process.exit(0);
})().catch(e => { console.error('TEST ERROR', e); process.exit(1); });
