<!doctype html>
<html lang="ko">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>환영도시 DSK 만들기</title>
<style>
:root{--bg:#f6f5f2;--card:#fff;--ink:#1d1d1f;--mute:#6b6b70;--line:#dcdad4;--acc:#1f5fd6;--acc-ink:#fff;--ok:#1a7f45;--bad:#b3261e;--warn:#8a5a00;--chip:#eceae4}
@media (prefers-color-scheme:dark){:root:not([data-theme="light"]){--bg:#141416;--card:#1e1e21;--ink:#ececee;--mute:#9a9aa2;--line:#33333a;--acc:#6ea0ff;--acc-ink:#0b1020;--ok:#5fd18a;--bad:#ff8a80;--warn:#f0c060;--chip:#2a2a2f}}
:root[data-theme="dark"]{--bg:#141416;--card:#1e1e21;--ink:#ececee;--mute:#9a9aa2;--line:#33333a;--acc:#6ea0ff;--acc-ink:#0b1020;--ok:#5fd18a;--bad:#ff8a80;--warn:#f0c060;--chip:#2a2a2f}
*{box-sizing:border-box}
[hidden]{display:none!important}
body{margin:0;background:var(--bg);color:var(--ink);font:15px/1.55 system-ui,-apple-system,"Segoe UI","Malgun Gothic","Apple SD Gothic Neo",sans-serif}
main{max-width:760px;margin:0 auto;padding:20px 16px 48px}
h1{font-size:22px;margin:8px 0 2px}
.sub{color:var(--mute);margin:0 0 18px}
section{background:var(--card);border:1px solid var(--line);border-radius:12px;padding:16px;margin:0 0 14px}
h2{font-size:15px;margin:0 0 10px;display:flex;align-items:center;gap:8px}
h2 .n{background:var(--acc);color:var(--acc-ink);border-radius:50%;width:22px;height:22px;display:inline-flex;align-items:center;justify-content:center;font-size:12px}
#drop{border:2px dashed var(--line);border-radius:10px;padding:26px 12px;text-align:center;color:var(--mute);cursor:pointer;transition:.15s}
#drop.over{border-color:var(--acc);background:color-mix(in srgb,var(--acc) 8%,transparent);color:var(--ink)}
#drop b{color:var(--ink)}
#drop small{display:block;margin-top:6px}
.checks{display:grid;grid-template-columns:repeat(auto-fill,minmax(150px,1fr));gap:6px;margin-top:12px}
.chip{background:var(--chip);border-radius:8px;padding:6px 10px;font-size:13px;display:flex;justify-content:space-between;gap:8px}
.chip.ok{color:var(--ok)}.chip.bad{color:var(--bad)}.chip.opt{color:var(--mute)}
.row{display:flex;flex-wrap:wrap;align-items:center;gap:8px 12px;margin:10px 0}
.row>label{min-width:132px;color:var(--mute)}
.seg{display:inline-flex;border:1px solid var(--line);border-radius:9px;overflow:hidden}
.seg button{border:0;background:transparent;color:var(--ink);padding:7px 13px;font:inherit;cursor:pointer;border-right:1px solid var(--line)}
.seg button:last-child{border-right:0}
.seg button[aria-pressed="true"]{background:var(--acc);color:var(--acc-ink)}
.seg button:disabled{opacity:.4;cursor:not-allowed}
.hint{color:var(--mute);font-size:13px;flex-basis:100%;margin:-4px 0 2px 0}
input[type=text]{border:1px solid var(--line);background:var(--bg);color:var(--ink);border-radius:8px;padding:7px 10px;font:inherit;width:190px}
.go{display:flex;flex-wrap:wrap;gap:10px;align-items:center}
button.primary{background:var(--acc);color:var(--acc-ink);border:0;border-radius:10px;padding:11px 20px;font:inherit;font-weight:600;cursor:pointer}
button.primary:disabled{opacity:.4;cursor:not-allowed}
button.dl{background:var(--chip);color:var(--ink);border:1px solid var(--line);border-radius:10px;padding:10px 16px;font:inherit;cursor:pointer}
button.dl:disabled{opacity:.4;cursor:not-allowed}
#msg{margin-top:10px;font-size:14px}
#msg.bad{color:var(--bad)}#msg.ok{color:var(--ok)}
pre{background:var(--bg);border:1px solid var(--line);border-radius:8px;padding:10px;font-size:12px;max-height:190px;overflow:auto;margin:10px 0 0;white-space:pre-wrap}
footer{color:var(--mute);font-size:12.5px;margin-top:14px}
@media(max-width:520px){.row>label{min-width:100%}}
</style>
</head>
<body>
<main>
<h1>환영도시(ILLUSION CITY) DSK 만들기</h1>
<p class="sub">게임 디스크와 DOS 파일을 올리면 MSX-DOS2 하드디스크용 <b>.dsk</b>(또는 SD 카드에 복사할 ZIP)를 만들어 줍니다. 모든 처리는 이 브라우저 안에서만 이뤄지고 파일은 어디로도 전송되지 않습니다.</p>

<section>
<h2><span class="n">1</span>파일 올리기</h2>
<div id="drop" tabindex="0" role="button" aria-label="파일 올리기">
  <b>여기로 파일을 끌어다 놓거나 눌러서 선택</b>
  <small>게임 디스크 8장(.dsk 또는 zip) · 유저 디스크(선택) · KANJI.rom(선택) · MSXDOS2.SYS + COMMAND2.COM 또는 NEXTOR.SYS (zip 가능)</small>
</div>
<input id="pick" type="file" multiple hidden>
<div class="checks" id="checks"></div>
<pre id="notes" hidden></pre>
</section>

<section>
<h2><span class="n">2</span>옵션</h2>
<div class="row"><label>시작할 때 자동 실행</label>
  <div class="seg" data-opt="autoexec"><button data-v="on">AUTOEXEC.BAT 사용</button><button data-v="off" aria-pressed="true">사용 안 함</button></div>
  <div class="hint">켜면 부팅하자마자 ICITY를 실행합니다. 런처 오류 메시지가 순식간에 지나갈 수 있어 처음에는 끄는 것을 권합니다.</div></div>
<div class="row"><label>글자(한글 폰트)</label>
  <div class="seg" data-opt="font"><button data-v="file" id="fontFile" disabled>FONT.BIN 사용</button><button data-v="rom" aria-pressed="true">기계의 한자 ROM 사용</button></div>
  <div class="hint" id="fontHint">KANJI.rom을 올리면 한자 ROM 없이도 한글이 나옵니다.</div></div>
<div class="row"><label>세이브</label>
  <div class="seg" data-opt="saves"><button data-v="keep" aria-pressed="true">올린 유저 디스크의 세이브 유지</button><button data-v="blank">빈 세이브로 시작</button></div></div>
<div class="row" id="dosRow" hidden><label>DOS 종류</label>
  <div class="seg" data-opt="dos"><button data-v="ascii" aria-pressed="true">ASCII DOS2</button><button data-v="nextor">Nextor</button></div>
  <div class="hint">두 종류의 파일이 모두 올라와 있어 선택합니다.</div></div>
<div class="row"><label>README.TXT 포함</label>
  <div class="seg" data-opt="readme"><button data-v="on" aria-pressed="true">포함</button><button data-v="off">제외</button></div></div>
<div class="row"><label>볼륨 이름</label><input id="label" type="text" value="ICITYDOS2" maxlength="11" spellcheck="false"></div>
</section>

<section>
<h2><span class="n">3</span>만들기</h2>
<div class="go">
  <button class="primary" id="make" disabled>만들기</button>
  <button class="dl" id="dlDsk" disabled>DSK 내려받기</button>
  <button class="dl" id="dlZip" disabled>ZIP 내려받기 (SD 카드용)</button>
</div>
<div id="msg"></div>
<pre id="log" hidden></pre>
</section>

<footer>
DSK: 16MB FAT12 하드디스크 이미지 (openMSX <code>-ext ide</code> / Nextor 확장의 <code>hda</code>). ZIP: 안의 ICITY.COM 과 ICITY 폴더를 SD 카드 루트에 복사하세요.
게임 데이터·DOS 파일·폰트는 앱에 들어 있지 않습니다. 앱에는 런처(ICITY.COM)와 부트 섹터만 들어 있습니다.
</footer>
</main>

<script id="assets" type="application/json">/*ASSETS*/</script>
<script>
/*CORE*/
</script>
<script>
(function(){
'use strict';
const A = JSON.parse(document.getElementById('assets').textContent);
const $ = id => document.getElementById(id);
const opts = { autoexec:'off', font:'rom', saves:'keep', dos:'ascii', readme:'on' };
let items = [], cls = null, result = null;

async function inflate(raw){
  if (typeof DecompressionStream === 'undefined') throw new Error('이 브라우저는 zip 해제를 지원하지 않습니다. 압축을 풀어서 올려 주세요. (Chrome/Edge/Firefox/Safari 최신 버전)');
  const s = new Blob([raw]).stream().pipeThrough(new DecompressionStream('deflate-raw'));
  return new Uint8Array(await new Response(s).arrayBuffer());
}
function segs(){
  document.querySelectorAll('.seg').forEach(seg => {
    seg.querySelectorAll('button').forEach(b => b.addEventListener('click', () => {
      if (b.disabled) return;
      opts[seg.dataset.opt] = b.dataset.v;
      seg.querySelectorAll('button').forEach(x => x.setAttribute('aria-pressed', x === b ? 'true' : 'false'));
      invalidate();
    }));
  });
}
function setSeg(name, v){ document.querySelectorAll('.seg[data-opt="'+name+'"] button').forEach(b => b.setAttribute('aria-pressed', b.dataset.v === v ? 'true' : 'false')); opts[name] = v; }
function invalidate(){ result = null; $('dlDsk').disabled = true; $('dlZip').disabled = true; }

async function ingest(files){
  for (const f of files) items.push({ name: f.name, data: new Uint8Array(await f.arrayBuffer()) });
  await refresh();
}
async function refresh(){
  invalidate(); $('msg').textContent = ''; $('msg').className = '';
  try { cls = await ICITY.classify(items, inflate); } catch (e) { cls = null; show('bad', e.message); return; }
  const c = $('checks'); c.innerHTML = '';
  const chip = (t, v, k) => { const d = document.createElement('div'); d.className = 'chip ' + k; d.innerHTML = '<span></span><span></span>'; d.children[0].textContent = t; d.children[1].textContent = v; c.appendChild(d); };
  for (let n = 1; n <= 8; n++) chip('게임 디스크 ' + n, cls.disks[n] ? '✓' : '없음', cls.disks[n] ? 'ok' : 'bad');
  chip('유저 디스크', cls.user ? '✓ ' + cls.user.name : '없음(빈 세이브)', cls.user ? 'ok' : 'opt');
  chip('한글 폰트', cls.font ? '✓ ' + cls.font.name : '없음', cls.font ? 'ok' : 'opt');
  const hasA = !!cls.dos['MSXDOS2.SYS'], hasN = !!cls.dos['NEXTOR.SYS'], hasC = !!cls.dos['COMMAND2.COM'];
  chip('MSXDOS2.SYS', hasA ? '✓' : '없음', hasA ? 'ok' : 'opt');
  chip('NEXTOR.SYS', hasN ? '✓' : '없음', hasN ? 'ok' : 'opt');
  chip('COMMAND2.COM', hasC ? '✓' : '없음', hasC ? 'ok' : 'opt');
  const notes = $('notes'); if (cls.notes.length) { notes.hidden = false; notes.textContent = cls.notes.join('\n'); } else notes.hidden = true;
  // option availability
  $('fontFile').disabled = !cls.font;
  if (!cls.font) { setSeg('font', 'rom'); $('fontHint').textContent = 'KANJI.rom(256KB)을 올리면 "FONT.BIN 사용"을 고를 수 있습니다. 지금은 기계의 한자 ROM(한글 패치판)이 필요합니다.'; }
  else { if (opts.font === 'rom' && !$('fontFile').dataset.userRom) setSeg('font', 'file'); $('fontHint').textContent = 'FONT.BIN 사용: 한자 ROM 없이도 한글이 나옵니다.'; }
  $('dosRow').hidden = !(hasA && hasN);
  if (hasA && !hasN) opts.dos = 'ascii'; else if (hasN && !hasA) opts.dos = 'nextor';
  const ok = [1,2,3,4,5,6,7,8].every(n => cls.disks[n]);
  $('make').disabled = !ok;
  if (!ok) show('bad', '게임 디스크 1~8이 모두 필요합니다. (디스크 라벨 IPROJ01~IPROJ08로 자동 인식합니다.)');
  else if (!hasA && !hasN) show('warn', 'DOS 시스템 파일이 없습니다. 만들 수는 있지만 이미지만으로는 부팅되지 않습니다.');
}
function show(kind, text){ const m = $('msg'); m.className = kind === 'bad' ? 'bad' : kind === 'ok' ? 'ok' : ''; m.style.color = kind === 'warn' ? 'var(--warn)' : ''; m.textContent = text; }

async function make(){
  $('make').disabled = true; invalidate(); const log = $('log'); log.hidden = false; log.textContent = '';
  const L = m => { log.textContent += m + '\n'; log.scrollTop = log.scrollHeight; };
  show('', '만드는 중...');
  await new Promise(r => setTimeout(r, 30));
  try {
    const use = Object.assign({}, cls, { dos: {} });
    const want = opts.dos === 'nextor' ? ['NEXTOR.SYS','COMMAND2.COM'] : ['MSXDOS2.SYS','COMMAND2.COM'];
    for (const n of want) if (cls.dos[n]) use.dos[n] = cls.dos[n];
    const r = ICITY.build({ assets: A, cls: use, autoexec: opts.autoexec === 'on', autoexecText: 'ICITY', readme: opts.readme === 'on',
      useFont: opts.font === 'file', keepSaves: opts.saves === 'keep', log: L });
    const label = ($('label').value || 'ICITYDOS2').replace(/[^A-Za-z0-9_ ]/g, '').slice(0, 11) || 'ICITYDOS2';
    const img = ICITY.makeImage(r.rootFiles, r.boot, label, new Date());
    const files = ICITY.flatten(r.rootFiles, '');
    result = { image: img.image, files, fontOn: r.fontOn, n: files.length, used: img.used, total: img.clusters, cb: img.clusterBytes };
    L('파일 ' + files.length + '개, 사용 클러스터 ' + img.used + '/' + img.clusters + ' (여유 ' + Math.round((img.clusters - img.used) * img.clusterBytes / 1048576 * 10) / 10 + 'MB)');
    $('dlDsk').disabled = false; $('dlZip').disabled = false;
    show('ok', '완료: DSK와 ZIP을 내려받을 수 있습니다.' + (r.fontOn ? '' : ' (한자 ROM 사용 설정: 한글 한자 ROM이 있는 기계에서만 글자가 나옵니다.)'));
  } catch (e) { show('bad', '오류: ' + e.message); L('오류: ' + e.message); }
  $('make').disabled = false;
}
function save(name, bytes, type){
  const a = document.createElement('a'); a.href = URL.createObjectURL(new Blob([bytes], { type: type || 'application/octet-stream' })); a.download = name;
  document.body.appendChild(a); a.click(); setTimeout(() => { URL.revokeObjectURL(a.href); a.remove(); }, 4000);
}
segs();
const drop = $('drop'), pick = $('pick');
drop.addEventListener('click', () => pick.click());
drop.addEventListener('keydown', e => { if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); pick.click(); } });
pick.addEventListener('change', () => { ingest(Array.from(pick.files)); pick.value = ''; });
['dragenter','dragover'].forEach(t => drop.addEventListener(t, e => { e.preventDefault(); drop.classList.add('over'); }));
['dragleave','drop'].forEach(t => drop.addEventListener(t, e => { e.preventDefault(); drop.classList.remove('over'); }));
drop.addEventListener('drop', e => ingest(Array.from(e.dataTransfer.files)));
document.querySelector('.seg[data-opt="font"] button[data-v="rom"]').addEventListener('click', () => { $('fontFile').dataset.userRom = '1'; });
document.querySelector('.seg[data-opt="font"] button[data-v="file"]').addEventListener('click', () => { delete $('fontFile').dataset.userRom; });
$('make').addEventListener('click', make);
$('dlDsk').addEventListener('click', () => result && save('ICITY' + (opts.autoexec === 'on' ? '_AUTO' : '') + '.dsk', result.image));
$('dlZip').addEventListener('click', () => result && save('ICITY_SD.zip', ICITY.zipWrite(result.files), 'application/zip'));
})();
</script>
</body>
</html>
