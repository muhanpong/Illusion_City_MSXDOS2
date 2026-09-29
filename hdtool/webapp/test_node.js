// node test_node.js <zip> <userdisk> <font> <sys dir> <out.dsk> : builds an image with core.js from the same inputs
const fs = require('fs'), zlib = require('zlib');
require('./core.js');
const [zipf, userf, fontf, sysdir, outf, mode] = process.argv.slice(2);
const A = JSON.parse(fs.readFileSync(__dirname + '/assets.json', 'utf8'));
const items = [{ name: zipf.split('/').pop(), data: new Uint8Array(fs.readFileSync(zipf)) }];
if (userf && userf !== '-') items.push({ name: userf.split('/').pop(), data: new Uint8Array(fs.readFileSync(userf)) });
if (fontf && fontf !== '-') items.push({ name: 'KANJI.rom', data: new Uint8Array(fs.readFileSync(fontf)) });
for (const n of fs.readdirSync(sysdir)) if (/\.(SYS|COM)$/i.test(n)) items.push({ name: n, data: new Uint8Array(fs.readFileSync(sysdir + '/' + n)) });
(async () => {
  const cls = await ICITY.classify(items, async raw => new Uint8Array(zlib.inflateRawSync(Buffer.from(raw))));
  console.log('disks:', Object.keys(cls.disks).join(','), 'user:', cls.user && cls.user.name, 'font:', !!cls.font, 'dos:', Object.keys(cls.dos).join(','), 'notes:', cls.notes);
  const r = ICITY.build({ assets: A, cls, autoexec: mode === 'auto', readme: true, useFont: true, log: m => console.log(' ', m) });
  const img = ICITY.makeImage(r.rootFiles, r.boot, 'ICITYDOS2', new Date());
  console.log('image', img.image.length, 'clusters used', img.used, '/', img.clusters);
  fs.writeFileSync(outf, img.image);
  const files = ICITY.flatten(r.rootFiles, '');
  const zip = ICITY.zipWrite(files);
  fs.writeFileSync(outf + '.zip', zip);
  console.log('files', files.length, 'zip', zip.length);
})().catch(e => { console.error('ERROR:', e.message); process.exit(1); });
