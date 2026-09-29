/* ICITY disk maker - core logic (browser and Node).  Port of hdtool/mkdos2/mkdos2.py + mkhd.py.
 *
 * Inputs (Uint8Array): the eight game disks (identified by the IPROJ0n label), an optional user disk,
 * an optional font (KANJI.rom layout), DOS system files.  Output: a file list and a FAT12 hard-disk image
 * (or a zip of the same files).  No data of the game is embedded; only the launcher and a boot sector are.
 * buildCart: the cartridge ROMs (Yamanooto / ASCII16-X, 4MB each), port of hdtool/cart/mkcart.py; the page carries
 * only the cartridge's own 16KB boot block per mapper, FRAY.DOS comes from the given disk 1.
 */
(function (root) {
  'use strict';
  const SEC = 512, DISK_BYTES = 737280, DISK_SECTORS = 1440, SYS_LEN = 14, SAVE_START = 0x578, SAVE_LEN = 0x10, SAVE_FILE = 96 * 1024;

  const u16 = (a, o) => a[o] | (a[o + 1] << 8);
  const hex4 = n => n.toString(16).toUpperCase().padStart(4, '0');
  const b64 = s => { if (typeof atob === 'function') { const t = atob(s), a = new Uint8Array(t.length); for (let i = 0; i < t.length; i++) a[i] = t.charCodeAt(i); return a; } return new Uint8Array(Buffer.from(s, 'base64')); };
  const hexBytes = h => { const a = new Uint8Array(h.length / 2); for (let i = 0; i < a.length; i++) a[i] = parseInt(h.substr(i * 2, 2), 16); return a; };
  const same = (a, off, b) => { for (let i = 0; i < b.length; i++) if (a[off + i] !== b[i]) return false; return true; };
  const asciiAt = (a, o, n) => String.fromCharCode.apply(null, Array.from(a.subarray(o, o + n)));

  /* ---------------------------------------------------------------- crc32 / zip reading and writing */
  const crcTable = (() => { const t = new Uint32Array(256); for (let n = 0; n < 256; n++) { let c = n; for (let k = 0; k < 8; k++) c = c & 1 ? 0xEDB88320 ^ (c >>> 1) : c >>> 1; t[n] = c >>> 0; } return t; })();
  function crc32(a) { let c = 0xFFFFFFFF; for (let i = 0; i < a.length; i++) c = crcTable[(c ^ a[i]) & 0xFF] ^ (c >>> 8); return (c ^ 0xFFFFFFFF) >>> 0; }

  /* list the entries of a zip: [{name, method, csize, usize, off}] */
  function zipEntries(z) {
    let e = -1;
    for (let i = z.length - 22; i >= Math.max(0, z.length - 65600); i--) if (z[i] === 0x50 && z[i + 1] === 0x4B && z[i + 2] === 5 && z[i + 3] === 6) { e = i; break; }
    if (e < 0) throw new Error('not a zip file');
    const n = u16(z, e + 10), dv = new DataView(z.buffer, z.byteOffset, z.byteLength);
    let p = dv.getUint32(e + 16, true); const out = [];
    for (let i = 0; i < n; i++) {
      if (dv.getUint32(p, true) !== 0x02014B50) throw new Error('bad zip directory');
      const method = u16(z, p + 10), csize = dv.getUint32(p + 20, true), usize = dv.getUint32(p + 24, true);
      const nl = u16(z, p + 28), xl = u16(z, p + 30), cl = u16(z, p + 32), off = dv.getUint32(p + 42, true);
      out.push({ name: asciiAt(z, p + 46, nl), method, csize, usize, off });
      p += 46 + nl + xl + cl;
    }
    return out;
  }
  async function zipRead(z, ent, inflate) {
    const dv = new DataView(z.buffer, z.byteOffset, z.byteLength);
    const start = ent.off + 30 + u16(z, ent.off + 26) + u16(z, ent.off + 28);
    const raw = z.subarray(start, start + ent.csize);
    if (ent.method === 0) return raw.slice();
    if (ent.method === 8) return inflate(raw);
    throw new Error('zip method ' + ent.method + ' not supported');
  }
  function zipWrite(files) { // files: [{path, data}] stored (no compression)
    const parts = [], cen = []; let off = 0;
    const d = new Date(), dt = (d.getHours() << 11) | (d.getMinutes() << 5) | (d.getSeconds() >> 1), dd = ((d.getFullYear() - 1980) << 9) | ((d.getMonth() + 1) << 5) | d.getDate();
    for (const f of files) {
      const name = new TextEncoder().encode(f.path), crc = crc32(f.data);
      const h = new Uint8Array(30 + name.length), v = new DataView(h.buffer);
      v.setUint32(0, 0x04034B50, true); v.setUint16(4, 20, true); v.setUint16(6, 0x0800, true); v.setUint16(8, 0, true);
      v.setUint16(10, dt, true); v.setUint16(12, dd, true); v.setUint32(14, crc, true); v.setUint32(18, f.data.length, true); v.setUint32(22, f.data.length, true); v.setUint16(26, name.length, true);
      h.set(name, 30); parts.push(h, f.data);
      const c = new Uint8Array(46 + name.length), w = new DataView(c.buffer);
      w.setUint32(0, 0x02014B50, true); w.setUint16(4, 20, true); w.setUint16(6, 20, true); w.setUint16(8, 0x0800, true); w.setUint16(10, 0, true);
      w.setUint16(12, dt, true); w.setUint16(14, dd, true); w.setUint32(16, crc, true); w.setUint32(20, f.data.length, true); w.setUint32(24, f.data.length, true);
      w.setUint16(28, name.length, true); w.setUint32(42, off, true); c.set(name, 46); cen.push(c);
      off += h.length + f.data.length;
    }
    const cenLen = cen.reduce((s, c) => s + c.length, 0), end = new Uint8Array(22), ev = new DataView(end.buffer);
    ev.setUint32(0, 0x06054B50, true); ev.setUint16(8, files.length, true); ev.setUint16(10, files.length, true); ev.setUint32(12, cenLen, true); ev.setUint32(16, off, true);
    return concat([...parts, ...cen, end]);
  }
  function concat(list) { const n = list.reduce((s, a) => s + a.length, 0), o = new Uint8Array(n); let p = 0; for (const a of list) { o.set(a, p); p += a.length; } return o; }

  /* ---------------------------------------------------------------- classify the dropped files */
  /* items: [{name, data}] (zips are opened).  Returns {disks:{1..8:{name,data}}, user, font, dos:{NAME:data}, notes:[]} */
  async function classify(items, inflate) {
    const res = { disks: {}, user: null, font: null, dos: {}, notes: [] };
    const flat = [];
    for (const it of items) {
      if (/\.zip$/i.test(it.name)) {
        let ents; try { ents = zipEntries(it.data); } catch (e) { res.notes.push(it.name + ': ' + e.message); continue; }
        for (const en of ents) {
          if (/\/$/.test(en.name)) continue;
          const base = en.name.split('/').pop();
          const wanted = en.usize === DISK_BYTES || en.usize === 262144 || /^(MSXDOS2\.SYS|COMMAND2\.COM|NEXTOR\.SYS)$/i.test(base);
          if (!wanted) continue;
          flat.push({ name: base, data: await zipRead(it.data, en, inflate), from: it.name });
        }
      } else flat.push({ name: it.name.split(/[\\/]/).pop(), data: it.data });
    }
    for (const f of flat) {
      const up = f.name.toUpperCase();
      if (f.data.length === DISK_BYTES) {
        const lab = asciiAt(f.data, 3, 7);
        const m = /^IPROJ0([1-8])$/.exec(lab);
        if (m) { if (res.disks[m[1]]) res.notes.push('disk ' + m[1] + ' twice: ' + f.name + ' ignored'); else res.disks[m[1]] = f; }
        else if (!res.user) res.user = f; else res.notes.push('another user disk candidate ignored: ' + f.name);
      } else if (f.data.length === 262144) res.font = f;
      else if (/^(MSXDOS2\.SYS|COMMAND2\.COM|NEXTOR\.SYS)$/.test(up)) res.dos[up] = f.data;
      else res.notes.push('ignored: ' + f.name + ' (' + f.data.length + ' bytes)');
    }
    return res;
  }

  /* ---------------------------------------------------------------- chunk analysis (mkdos2.py) */
  function fileTable(img) { const t = img.subarray(11 * SEC, 12 * SEC), out = []; for (let i = 0; i < 256; i++) { const s = t[2 * i], c = t[2 * i + 1]; if (s === 0 && c === 0) break; out.push([s, c]); } return out; }
  function infRanges(img, ftab) {
    const r = [];
    if (ftab.length <= 6) return r;
    const [st, cnt] = ftab[6], inf = img.subarray(st * SEC, (st + cnt) * SEC);
    if (asciiAt(inf, 0, 3) !== 'INF' || inf[3] !== 0) return r;
    const used = u16(inf, 4), namelen = u16(inf, 6), nrec = Math.floor(namelen / 26);
    if (nrec * 26 !== namelen) throw new Error('INF catalogue layout not understood');
    for (let k = 0; k < nrec; k++) for (let j = 0; j < 7; j++) { const o = 0x20 + 26 * k + 3 + 3 * j, l = inf[o + 2]; if (l) r.push([u16(inf, o), l]); }
    for (let pos = 0x20 + namelen; pos + 3 <= used; pos += 3) { const l = inf[pos + 2]; if (l) r.push([u16(inf, pos), l]); }
    return r;
  }
  function chunkStarts(img, tag) {
    const ranges = []; if (tag !== 'U') { const ft = fileTable(img); for (const [s, c] of ft) if (c) ranges.push([s, c]); ranges.push(...infRanges(img, ft)); }
    const fixed = [[0, SYS_LEN]]; if (tag === '1' || tag === 'U') fixed.push([SAVE_START, SAVE_LEN]);
    const b = new Set([0, DISK_SECTORS]);
    for (const [s, l] of ranges) { if (s + l > DISK_SECTORS) throw new Error('range outside disk ' + tag); b.add(s); b.add(s + l); }
    for (const [s, l] of fixed) { b.add(s); b.add(s + l); }
    return Array.from(b).sort((x, y) => x - y);
  }

  /* ---------------------------------------------------------------- FAT12 image */
  function makeImage(rootFiles, boot, label, when) {
    // rootFiles: tree nodes {name, data} or {name, dir:[...]}; boot: 512-byte template with the BPB
    const bps = u16(boot, 0x0B), spc = boot[0x0D], res = u16(boot, 0x0E), nfat = boot[0x10], rootEnt = u16(boot, 0x11), total = u16(boot, 0x13), media = boot[0x15], spf = u16(boot, 0x16);
    const img = new Uint8Array(total * bps), rootSec = Math.ceil(rootEnt * 32 / bps), dataStart = res + nfat * spf + rootSec, csz = spc * bps;
    const nclus = Math.floor((total - dataStart) / spc);
    if (nclus > 4084) throw new Error('template geometry is not FAT12');
    img.set(boot, 0);
    const fat = new Uint16Array(nclus + 2); fat[0] = 0xF00 | media; fat[1] = 0xFFF;
    let next = 2;
    const dosDate = ((when.getFullYear() - 1980) << 9) | ((when.getMonth() + 1) << 5) | when.getDate(), dosTime = (when.getHours() << 11) | (when.getMinutes() << 5) | (when.getSeconds() >> 1);
    const alloc = n => { const c = Math.max(1, Math.ceil(n / csz)); if (next - 2 + c > nclus) throw new Error('image is full'); const first = next; for (let i = 0; i < c; i++) { fat[next] = i === c - 1 ? 0xFFF : next + 1; next++; } return first; };
    const clusOff = c => (dataStart + (c - 2) * spc) * bps;
    const name83 = n => { const [b, e = ''] = n.toUpperCase().split('.'); if (b.length > 8 || e.length > 3 || !/^[A-Z0-9_\-!#$%&'()@^`{}~]+$/.test(b) || !/^[A-Z0-9_\-!#$%&'()@^`{}~]*$/.test(e)) throw new Error('bad 8.3 name ' + n); return (b.padEnd(8) + e.padEnd(3)); };
    const entry = (n, attr, cl, size) => { const e = new Uint8Array(32); for (let i = 0; i < 11; i++) e[i] = n.charCodeAt(i); e[11] = attr; e[22] = dosTime & 255; e[23] = dosTime >> 8; e[24] = dosDate & 255; e[25] = dosDate >> 8; e[26] = cl & 255; e[27] = cl >> 8; e[28] = size & 255; e[29] = (size >> 8) & 255; e[30] = (size >> 16) & 255; e[31] = (size >>> 24) & 255; return e; };
    // directories need their clusters before their entries are final: two passes
    function build(nodes, selfCl, parentCl, isRoot) {
      const list = []; if (!isRoot) { list.push(entry('.          ', 0x10, selfCl, 0)); list.push(entry('..         ', 0x10, parentCl, 0)); }
      if (isRoot && label) list.push(entry((label.toUpperCase() + '           ').slice(0, 11), 0x08, 0, 0));
      const dirs = [];
      for (const nd of nodes) {
        if (nd.dir) dirs.push(nd);
        else { const cl = alloc(nd.data.length); img.set(nd.data, clusOff(cl)); list.push(entry(name83(nd.name), 0x20, cl, nd.data.length)); }
      }
      for (const nd of dirs) {
        const need = 2 + nd.dir.length; // upper bound of entries (dirs inside dirs count 1 each)
        const cl = alloc(Math.max(1, need) * 32); // provisional; grown below if more clusters are needed
        list.push(entry(name83(nd.name), 0x10, cl, 0)); nd.cl = cl;
      }
      if (isRoot) { if (list.length > rootEnt) throw new Error('root directory full'); const o = (res + nfat * spf) * bps; list.forEach((e, i) => img.set(e, o + i * 32)); }
      else { let cl = selfCl; list.forEach((e, i) => { const per = csz / 32, k = Math.floor(i / per); let c = selfCl; for (let j = 0; j < k; j++) c = fat[c]; img.set(e, clusOff(c) + (i % per) * 32); }); }
      for (const nd of dirs) build(nd.dir, nd.cl, selfCl, false);
    }
    build(rootFiles, 0, 0, true);
    // FAT copies
    const f = new Uint8Array(spf * bps);
    for (let i = 0; i < fat.length; i += 2) { const a = fat[i], b = i + 1 < fat.length ? fat[i + 1] : 0, o = (i >> 1) * 3; if (o + 2 < f.length) { f[o] = a & 255; f[o + 1] = ((a >> 8) & 15) | ((b & 15) << 4); f[o + 2] = b >> 4; } }
    for (let k = 0; k < nfat; k++) img.set(f, (res + k * spf) * bps);
    return { image: img, used: next - 2, clusters: nclus, clusterBytes: csz };
  }

  /* ---------------------------------------------------------------- the build */
  /* opts: {assets, cls (from classify), autoexec:boolean, autoexecText, readme:boolean, label, useFont:boolean, log(fn)} */
  function build(opts) {
    const A = opts.assets, log = opts.log || (() => { }), cls = opts.cls;
    const com = b64(A.com), boot = b64(A.boot);
    const disks = {};
    for (let n = 1; n <= 8; n++) { const d = cls.disks[n]; if (!d) throw new Error('game disk ' + n + ' (IPROJ0' + n + ') is missing'); disks[n] = d.data.slice(); }
    // user disk: given, or blank with disk 1's boot sector (as build_icity_hd.py does)
    let user;
    if (cls.user && opts.keepSaves !== false) { user = cls.user.data.slice(); log('user disk: ' + cls.user.name); }
    else { user = new Uint8Array(DISK_BYTES); user.set(disks[1].subarray(0, SEC), 0); user.set(new TextEncoder().encode('USERDISK'), 3); log('user disk: blank'); }
    disks.U = user;
    // patches (disk 1)
    const fontOn = !!(opts.useFont && cls.font);
    const applied = [];
    for (const p of A.patches) {
      if (p.font && !fontOn) continue;
      const o = p.sector * SEC + p.offset, orig = hexBytes(p.orig), nw = hexBytes(p.new);
      if (!same(disks[p.disk], o, orig)) throw new Error('patch ' + p.id + ': the bytes on disk ' + p.disk + ' do not match - this is not the supported release');
      disks[p.disk].set(nw, o); applied.push(p.id);
    }
    log('patches applied: ' + applied.join(' '));
    // chunk tables must equal the ones compiled into the launcher
    const tree = { 'ICITY': [] }, icity = [], chunks = {};
    let count = 0;
    for (const tag of ['1', '2', '3', '4', '5', '6', '7', '8', 'U']) {
      const st = chunkStarts(disks[tag], tag), exp = A.expected[tag];
      const starts = st.slice(0, -1);
      if (starts.length !== exp.length || starts.some((v, i) => v !== exp[i])) throw new Error('disk ' + tag + ': chunk layout differs from the launcher\'s tables (different release?)');
      const dn = 'D' + tag, dir = [];
      for (let i = 0; i < starts.length; i++) {
        const a = starts[i], b = st[i + 1], nm = dn + '_' + hex4(a) + '.DAT', data = disks[tag].subarray(a * SEC, b * SEC);
        if (a === SAVE_START && (tag === '1' || tag === 'U')) {   // 96 slots of 1KB (paged slot list, patches P1-P6)
          const sv = new Uint8Array(SAVE_FILE); sv.set(data, 0); (chunks.SAVE = chunks.SAVE || []).push({ name: nm, data: sv }); }
        else dir.push({ name: nm, data });
        count++;
      }
      chunks[dn] = dir;
    }
    log('chunks: ' + count);
    const dirNodes = ['D1', 'D2', 'D3', 'D4', 'D5', 'D6', 'D7', 'D8', 'DU', 'SAVE'].map(n => ({ name: n === 'DU' ? 'DU' : n, dir: chunks[n === 'DU' ? 'DU' : n] || [] }));
    const icityDir = dirNodes; if (fontOn) icityDir.push({ name: 'FONT.BIN', data: cls.font.data });
    const rootFiles = [];
    const dosNames = ['NEXTOR.SYS', 'MSXDOS2.SYS', 'COMMAND2.COM'];
    let any = false; for (const n of dosNames) if (cls.dos[n]) { rootFiles.push({ name: n, data: cls.dos[n] }); any = true; }
    if (!any) log('warning: no DOS system files - the image will not boot by itself');
    rootFiles.push({ name: 'ICITY.COM', data: com });
    if (opts.autoexec) rootFiles.push({ name: 'AUTOEXEC.BAT', data: new TextEncoder().encode((opts.autoexecText || 'ICITY') + '\r\n') });
    if (opts.readme) rootFiles.push({ name: 'README.TXT', data: new TextEncoder().encode(A.readme.replace(/\r?\n/g, '\r\n')) });
    rootFiles.push({ name: 'ICITY', dir: icityDir });
    return { rootFiles, boot, applied, fontOn, chunkCount: count };
  }
  function flatten(nodes, prefix, out) { out = out || []; for (const n of nodes) { if (n.dir) flatten(n.dir, prefix + n.name + '/', out); else out.push({ path: prefix + n.name, data: n.data }); } return out; }

  /* ---------------------------------------------------------------- ZX0 compressor (port of ZX0 v2.2 by Einar Saukas,
     BSD-3, src/optimize.c + src/compress.c; forward, modern format; output identical to the C tool) */
  function zx0(input) {
    const size = input.length, INITIAL_OFFSET = 1, MAX_OFFSET = 32640;
    const egb = v => { let b = 1; while (v >>= 1) b += 2; return b; };
    const ceil = i => i > MAX_OFFSET ? MAX_OFFSET : i < INITIAL_OFFSET ? INITIAL_OFFSET : i;
    let maxOff = ceil(size - 1);
    const lastLit = new Array(maxOff + 1).fill(null), lastMatch = new Array(maxOff + 1).fill(null);
    const optimal = new Array(size).fill(null), matchLen = new Int32Array(maxOff + 1), best = new Int32Array(size + 1);
    if (size > 2) best[2] = 2;
    const blk = (bits, index, offset, chain) => ({ bits, index, offset, chain });
    lastMatch[INITIAL_OFFSET] = blk(-1, -1, INITIAL_OFFSET, null);
    for (let index = 0; index < size; index++) {
      let bestSize = 2;
      maxOff = ceil(index);
      for (let offset = 1; offset <= maxOff; offset++) {
        if (index !== 0 && index >= offset && input[index] === input[index - offset]) {
          if (lastLit[offset]) {
            const length = index - lastLit[offset].index, bits = lastLit[offset].bits + 1 + egb(length);
            lastMatch[offset] = blk(bits, index, offset, lastLit[offset]);
            if (!optimal[index] || optimal[index].bits > bits) optimal[index] = lastMatch[offset];
          }
          if (++matchLen[offset] > 1) {
            if (bestSize < matchLen[offset]) {
              let bits = optimal[index - best[bestSize]].bits + egb(best[bestSize] - 1);
              do {
                bestSize++;
                const bits2 = optimal[index - bestSize].bits + egb(bestSize - 1);
                if (bits2 <= bits) { best[bestSize] = bestSize; bits = bits2; } else best[bestSize] = best[bestSize - 1];
              } while (bestSize < matchLen[offset]);
            }
            const length = best[matchLen[offset]];
            const bits = optimal[index - length].bits + 8 + egb(Math.floor((offset - 1) / 128) + 1) + egb(length - 1);
            if (!lastMatch[offset] || lastMatch[offset].index !== index || lastMatch[offset].bits > bits) {
              lastMatch[offset] = blk(bits, index, offset, optimal[index - length]);
              if (!optimal[index] || optimal[index].bits > bits) optimal[index] = lastMatch[offset];
            }
          }
        } else {
          matchLen[offset] = 0;
          if (lastMatch[offset]) {
            const length = index - lastMatch[offset].index, bits = lastMatch[offset].bits + 1 + egb(length) + length * 8;
            lastLit[offset] = blk(bits, index, 0, lastMatch[offset]);
            if (!optimal[index] || optimal[index].bits > bits) optimal[index] = lastLit[offset];
          }
        }
      }
    }
    // emit
    let opt = optimal[size - 1];
    const out = new Uint8Array(Math.floor((opt.bits + 25) / 8));
    let prev = null;
    while (opt) { const next = opt.chain; opt.chain = prev; prev = opt; opt = next; }
    let oi = 0, ii = 0, bitIndex = 0, bitMask = 0, backtrack = true, lastOffset = INITIAL_OFFSET;
    const wbyte = v => { out[oi++] = v; };
    const wbit = v => {
      if (backtrack) { if (v) out[oi - 1] |= 1; backtrack = false; }
      else { if (!bitMask) { bitMask = 128; bitIndex = oi; wbyte(0); } if (v) out[bitIndex] |= bitMask; bitMask >>= 1; }
    };
    const gamma = (value, invert) => {
      let i = 2; while (i <= value) i <<= 1; i >>= 1;
      while (i >>= 1) { wbit(0); wbit(invert ? !(value & i) : (value & i)); }
      wbit(1);
    };
    for (opt = prev.chain; opt; prev = opt, opt = opt.chain) {
      const length = opt.index - prev.index;
      if (!opt.offset) { wbit(0); gamma(length, false); for (let i = 0; i < length; i++) wbyte(input[ii++]); }
      else if (opt.offset === lastOffset) { wbit(0); gamma(length, false); ii += length; }
      else {
        wbit(1); gamma(Math.floor((opt.offset - 1) / 128) + 1, true);
        wbyte((127 - (opt.offset - 1) % 128) << 1);
        backtrack = true; gamma(length - 1, false); ii += length; lastOffset = opt.offset;
      }
    }
    wbit(1); gamma(256, true);
    return out;
  }

  /* ---------------------------------------------------------------- cartridge ROMs (hdtool/cart/mkcart.py) */
  /* root-directory file of a FAT12 disk image */
  function fat12File(disk, name) {
    const bps = u16(disk, 11), spc = disk[13], res = u16(disk, 14), nfat = disk[16], nroot = u16(disk, 17), spf = u16(disk, 22);
    const root = (res + nfat * spf) * bps, data = root + nroot * 32, fat = disk.subarray(res * bps, (res + spf) * bps);
    for (let i = 0; i < nroot; i++) {
      const e = root + i * 32;
      if (asciiAt(disk, e, 11) !== name) continue;
      let cl = u16(disk, e + 26); const size = (u16(disk, e + 28) | (u16(disk, e + 30) << 16)) >>> 0, out = new Uint8Array(size);
      let p = 0;
      while (cl >= 2 && cl < 0xFF8 && p < size) {
        const off = data + (cl - 2) * spc * bps, n = Math.min(spc * bps, size - p);
        out.set(disk.subarray(off, off + n), p); p += n;
        const v = u16(fat, (cl * 3) >> 1); cl = cl & 1 ? v >> 4 : v & 0xFFF;
      }
      if (p < size) throw new Error(name.trim() + ': FAT chain shorter than the file');
      return out;
    }
    throw new Error('disk 1 has no ' + name.replace(/ +/, '.').trim());
  }
  /* opts: {assets, cls, keepSaves, log} -> [{tag, name, rom}] */
  function buildCart(opts) {
    const C = opts.assets.cart, log = opts.log || (() => { }), cls = opts.cls;
    const disks = [];
    for (let n = 1; n <= 8; n++) { const d = cls.disks[n]; if (!d) throw new Error('game disk ' + n + ' (IPROJ0' + n + ') is missing'); disks.push(d.data.slice()); }
    if (!cls.font) throw new Error('the cartridge needs the font (KANJI.rom, 262144 bytes)');
    if (cls.font.data.length !== C.fontSize) throw new Error('font: expected ' + C.fontSize + ' bytes');
    let user;
    if (cls.user && opts.keepSaves !== false) { user = cls.user.data; log('user disk: ' + cls.user.name); }
    else { user = new Uint8Array(DISK_BYTES); user.set(disks[0].subarray(0, SEC), 0); user.set(new TextEncoder().encode('USERDISK'), 3); log('user disk: blank'); }
    const fray = fat12File(disks[0], 'FRAY    DOS');
    if (fray.length !== C.frayLen) throw new Error('FRAY.DOS is ' + fray.length + ' bytes, the cartridge was built for ' + C.frayLen + ' - this is not the supported release');
    // patch G1: the game's glyph fetch -> the cartridge's font
    const g = C.g1, o = g.sector * SEC + g.offset;
    if (!g.orig.some(h => same(disks[0], o, hexBytes(h)))) throw new Error('patch G1: the bytes on disk 1 do not match - this is not the supported release');
    disks[0].set(hexBytes(g.new), o);
    // save-list paging (file9, loaded at 4000h): 96 slots per disk
    for (const p of C.ui) {
      const q = C.file9Sec * SEC + p.addr - C.file9Base;
      if (!same(disks[0], q, hexBytes(p.orig))) throw new Error('save-list patch at ' + hex4(p.addr) + ': the bytes on disk 1 do not match - this is not the supported release');
      disks[0].set(hexBytes(p.new), q);
    }
    log('FRAY.DOS ' + fray.length + ' bytes, patches G1 + save-list paging (' + C.ui.length + ') applied');
    // sectors of disk 1-8 + user disk: duplicates once, each ZX0 (raw when not smaller), none across an 8KB bank;
    // table: low word at tblLo + 2i, high byte at tblHi + i (offset | raw<<13 | bank<<14)
    const all = [...disks, user], nsec = 9 * DISK_SECTORS;
    const blob = new Uint8Array(C.dataEnd - C.data).fill(0xFF), lo = new Uint8Array(2 * nsec), hi = new Uint8Array(nsec);
    const where = new Map(); let used = 0;
    const dec = new TextDecoder('latin1');
    for (let i = 0; i < nsec; i++) {
      const d = all[Math.floor(i / DISK_SECTORS)], s = d.subarray((i % DISK_SECTORS) * SEC, (i % DISK_SECTORS + 1) * SEC);
      const key = dec.decode(s);
      let w = where.get(key);
      if (!w) {
        const z = zx0(s), raw = z.length >= SEC, item = raw ? s : z;
        if ((used & 0x1FFF) + item.length > 0x2000) used = (used | 0x1FFF) + 1;
        if (used + item.length > blob.length) throw new Error('packed data does not fit');
        w = { bank: (C.data + used) >> 13, off: used & 0x1FFF, raw };
        blob.set(item, used); used += item.length; where.set(key, w);
      }
      const v = w.off | (w.raw ? 0x2000 : 0) | (w.bank << 14);
      lo[2 * i] = v & 0xFF; lo[2 * i + 1] = (v >> 8) & 0xFF; hi[i] = v >> 16;
    }
    log(nsec + ' sectors (' + where.size + ' distinct) packed to ' + Math.round(used / 1024) + 'KB');
    const out = [];
    for (const m of C.mappers) {
      const rom = new Uint8Array(m.fileSize || C.romSize).fill(0xFF);
      rom.set(b64(m.boot), 0);
      rom.set(fray, m.frayOff);
      rom.set(lo, C.tblLo); rom.set(hi, C.tblHi);
      rom.set(blob.subarray(0, used), C.data);
      rom.set(cls.font.data, C.font);
      // save slots: group g in flash sector g (header 'IC', g, generation 1), sector nsave-1 spare
      for (let g = 0; g < 2 * C.slots / C.group; g++) rom.set([0x49, 0x43, g, 1, 0], C.save + g * 0x10000 + 0xC000);
      [disks[0], user].forEach((d, area) => { for (let n = 0; n < 8; n++) {
        const slot = area * C.slots + n, g = Math.floor(slot / C.group), p = slot % C.group, src = (C.saveFirst + 2 * n) * SEC;
        rom.set(d.subarray(src, src + 2 * SEC), C.save + g * 0x10000 + (p >> 3) * 0x4000 + (p & 7) * 0x400); } });
      out.push({ tag: m.tag, name: m.name, rom });
    }
    log('ROM: ' + out.map(r => r.name + ' ' + (r.rom.length >> 20) + 'MB').join(', ') + ' (content ' + (C.romSize >> 20) + 'MB)');
    return out;
  }

  root.ICITY = { classify, build, buildCart, fat12File, zx0, makeImage, flatten, zipWrite, zipEntries, zipRead, crc32, chunkStarts, b64, hexBytes };
})(typeof window !== 'undefined' ? window : globalThis);
