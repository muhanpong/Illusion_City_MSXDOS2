<!doctype html>
<html lang="ko">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>환영도시 HDD·ROM·플로피 만들기</title>
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
.need{width:100%;border-collapse:collapse;font-size:13px;margin:0 0 16px}
.need th,.need td{border-bottom:1px solid var(--line);padding:6px 8px;text-align:left;vertical-align:top}
.need th{color:var(--mute);font-weight:600}
.need td.y{color:var(--ok);font-weight:600}.need td.n{color:var(--warn);font-weight:600}
.need tr.cur td{background:color-mix(in srgb,var(--acc) 8%,transparent)}
.tbl{overflow-x:auto}
.slots{display:grid;grid-template-columns:repeat(auto-fit,minmax(260px,1fr));gap:10px;margin-top:12px}
.slots h3{font-size:13px;margin:0 0 4px;color:var(--mute);font-weight:600}
.slots table{width:100%;border-collapse:collapse;font-size:13px}
.slots td,.slots th{padding:3px 6px;border-bottom:1px solid var(--line);text-align:left}
.slots th{color:var(--mute);font-weight:600}.slots td.e{color:var(--mute)}.slots td.num{text-align:right;width:3em}
@media(max-width:520px){.row>label{min-width:100%}}
</style>
</head>
<body>
<main>
<h1>환영도시(ILLUSION CITY) HDD·ROM·플로피 만들기</h1>
<p class="sub">게임 디스크를 올리면 MSX-DOS2 하드디스크 이미지 <b>.hd.dsk</b>(또는 SD 카드에 복사할 ZIP), 꽂기만 하면 되는 <b>카트리지 ROM</b>(Yamanooto / ASCII16-X), 또는 한글 한자 ROM 없이 도는 <b>플로피</b>(원본 8장 중 디스크 1만 수정)를 만들어 줍니다. 모든 처리는 이 브라우저 안에서만 이뤄지고 파일은 어디로도 전송되지 않습니다.</p>
<div class="tbl"><table class="need" id="need">
<tr><th>만들 것</th><th>실행하는 방법</th><th>실행할 기계에 한글 한자 ROM</th><th>만들 때 KANJI.rom</th></tr>
<tr data-t="dsk"><td>DOS2 하드디스크 (HDD / SD)</td><td>MSX-DOS2·Nextor 하드디스크나 SD 카드에서 ICITY.COM</td><td class="y">필요 없음 (FONT.BIN을 넣을 때)<br><span style="color:var(--warn)">넣지 않으면 필요</span></td><td>선택 (FONT.BIN용)</td></tr>
<tr data-t="cart"><td>카트리지 ROM</td><td>Yamanooto·ASCII16-X 카트리지를 꽂고 켜기</td><td class="y">필요 없음</td><td>필수</td></tr>
<tr data-t="fdd"><td>플로피</td><td>원본처럼 디스크 8장 + 유저 디스크</td><td class="y">필요 없음<br><span style="color:var(--mute);font-weight:400">512KB 매퍼 기계. 256KB 기계는 필요</span></td><td>필수</td></tr>
</table></div>
<p class="sub" style="margin-top:-8px">KANJI.rom(262144바이트)은 키티야 님이 만드신 한글 한자 ROM 파일입니다. 만들 때 여기서 글꼴을 가져와 결과물에 넣을 뿐이고, 결과물을 실행하는 기계와는 상관없습니다.</p>
<p class="sub">이 도구와 여기서 만드는 결과물은 환영도시의 한글 번역과 한글 글꼴(KANJI.rom), 인코딩 작업을 해 주신 <b>키티야 님</b>께 감사의 마음을 담아 드립니다. 화면에 나오는 한글은 모두 키티야 님의 작업입니다. (<a href="https://blog.naver.com/kkitty5425/222619726741" target="_blank" rel="noopener">키티야 님의 환영도시 한글화 글</a>)</p>

<section>
<h2><span class="n">1</span>파일 올리기</h2>
<div id="drop" tabindex="0" role="button" aria-label="파일 올리기">
  <b>여기로 파일을 끌어다 놓거나 눌러서 선택</b>
  <small>게임 디스크 8장(.dsk 또는 zip) · 유저 디스크(선택) · KANJI.rom(카트리지·플로피는 필수, HDD는 선택) · MSXDOS2.SYS + COMMAND2.COM 또는 NEXTOR.SYS (HDD만, zip 가능)</small>
</div>
<input id="pick" type="file" multiple hidden>
<div class="checks" id="checks"></div>
<div class="slots" id="slots" hidden></div>
<pre id="notes" hidden></pre>
<p class="sub" id="en8note" hidden>English 8-disc release (translation by <b>MSX Translations</b>) detected: needs only the eight game disks (a user disk is optional; a Japanese "Data Disk" works as one). No Kanji ROM and no KANJI.rom are needed, and the floppy version is not offered. DOS2: <code>ICITY.COM</code> + <code>ICITY\</code> (96 save slots per disk); cartridge: Yamanooto / ASCII16-X ROMs. Credit for the English translation goes to MSX Translations.</p>
</section>

<section>
<h2><span class="n">2</span>옵션</h2>
<div class="row"><label>만들 것</label>
  <div class="seg" data-opt="target"><button data-v="dsk" aria-pressed="true">DOS2 하드디스크 (HDD / SD)</button><button data-v="cart">카트리지 ROM</button><button data-v="fdd">플로피 (원본 디스크 8장)</button></div>
  <div class="hint" id="targetHint"></div>
  <div class="hint" id="runHint"></div></div>
<div class="row dsk-only"><label>시작할 때 자동 실행</label>
  <div class="seg" data-opt="autoexec"><button data-v="on">AUTOEXEC.BAT 사용</button><button data-v="off" aria-pressed="true">사용 안 함</button></div>
  <div class="hint">켜면 부팅하자마자 ICITY를 실행합니다. 런처 오류 메시지가 순식간에 지나갈 수 있어 처음에는 끄는 것을 권합니다.</div></div>
<div class="row dsk-only" id="fontRow"><label>실행할 때 글자</label>
  <div class="seg" data-opt="font"><button data-v="file" id="fontFile" disabled>FONT.BIN (한글 한자 ROM 불필요)</button><button data-v="rom" aria-pressed="true">기계의 한글 한자 ROM</button></div>
  <div class="hint" id="fontHint"></div></div>
<div class="row" id="savesRow"><label>세이브</label>
  <div class="seg" data-opt="saves"><button data-v="keep" aria-pressed="true">올린 유저 디스크의 세이브 유지</button><button data-v="blank">빈 세이브로 시작</button></div></div>
<div class="row dsk-only" id="dosRow" hidden><label>DOS 종류</label>
  <div class="seg" data-opt="dos"><button data-v="ascii" aria-pressed="true">ASCII DOS2</button><button data-v="nextor">Nextor</button></div>
  <div class="hint">두 종류의 파일이 모두 올라와 있어 선택합니다.</div></div>
<div class="row dsk-only"><label>README.TXT 포함</label>
  <div class="seg" data-opt="readme"><button data-v="on" aria-pressed="true">포함</button><button data-v="off">제외</button></div></div>
<div class="row dsk-only"><label>볼륨 이름</label><input id="label" type="text" value="ICITYDOS2" maxlength="11" spellcheck="false"></div>
</section>

<section>
<h2><span class="n">3</span>만들기</h2>
<div class="go">
  <button class="primary" id="make" disabled>만들기</button>
  <button class="dl" id="dlDsk" disabled>하드디스크 이미지 내려받기 (.hd.dsk)</button>
  <button class="dl" id="dlZip" disabled>ZIP 내려받기 (SD 카드용)</button>
  <button class="dl" id="dlYAMA" disabled hidden>Yamanooto ROM 내려받기</button>
  <button class="dl" id="dlA16X" disabled hidden>ASCII16-X ROM 내려받기</button>
  <button class="dl" id="dlD1" disabled hidden>디스크 1 내려받기 (D1.dsk)</button>
  <button class="dl" id="dlFddZip" disabled hidden>ZIP 내려받기 (디스크 8장)</button>
</div>
<div id="msg"></div>
<pre id="log" hidden></pre>
</section>

<footer>
도구 버전 2026-10-01 — 엔딩 인트로의 글자까지 글꼴로 나오게 한 판입니다(DOS2·카트리지·플로피). 이 날짜 이전에 만든 DOS2·카트리지 결과물은 한자 ROM 없는 기계에서 엔딩 인트로 글자가 깨지므로 다시 만들어 주세요.<br>
HDD: 16MB FAT12 하드디스크 이미지(헤더 없는 원시 섹터 이미지). openMSX: IDE·Nextor 확장을 붙이고 <code>hda ICITY.hd.dsk</code>(openMSX도 하드디스크를 hd.dsk로 부름). MiSTer: 내용이 같으므로 확장자만 <code>.vhd</code>로 바꿔 쓰세요. ZIP: 안의 ICITY.COM 과 ICITY 폴더를 SD 카드 루트에 복사하세요.
ROM: 내용 4MB(4MB 이상 플래시의 Yamanooto 또는 ASCII16-X 카트리지용, 매퍼마다 파일 하나, 만드는 데 몇십 초). ASCII16-X 파일에는 0010h에 "ASCII16X" 서명이 있어 openMSX와 MiSTer 코어(매퍼 auto)가 플래시 매퍼로 인식합니다. 카트리지만 꽂고 켜면 시작하고, 한글은 ROM 안의 글꼴로 나오며(실행하는 기계에 한글 한자 ROM 불필요), 디스크 1·유저 디스크 슬롯 세이브는 카트리지 플래시에 기록됩니다. openMSX: <code>-carta ICITY_YAMA.rom -romtype Yamanooto</code>.
플로피: 디스크 1의 빈 섹터(550h~)에 게임이 쓰는 글자 1395자만 압축해 넣고, 한자 ROM 대신 그 글꼴을 읽게 합니다. FM·MIDI 모두 동작합니다.
<b>실행할 기계에 한글 한자 ROM이 필요한가</b> — HDD + FONT.BIN: 필요 없음 · HDD + 기계의 한자 ROM: 필요 · 카트리지: 필요 없음 · 플로피: 필요 없음(512KB 매퍼 기계. 256KB 기계에서는 필요).
<b>만들 때의 KANJI.rom</b>은 키티야 님이 만드신 한글 한자 ROM 파일로, 여기서 글꼴을 가져와 결과물에 넣는 데만 씁니다. 결과물을 실행하는 기계와는 상관없습니다.
한글 번역·한글 글꼴·인코딩: 키티야 님 (<a href="https://blog.naver.com/kkitty5425/222619726741" target="_blank" rel="noopener">한글화 글</a>). 이 도구는 그 작업을 여러 방식으로 즐길 수 있게 옮기는 도구입니다.
게임 데이터·DOS 파일·폰트는 앱에 들어 있지 않습니다. 앱에는 런처(ICITY.COM), 부트 섹터, 카트리지 부트 코드, 플로피 패치 코드만 들어 있습니다.
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
const opts = { target:'dsk', autoexec:'off', font:'rom', saves:'keep', dos:'ascii', readme:'on' };
let items = [], cls = null, result = null, roms = null, fdd = null;

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
      invalidate(); if (seg.dataset.opt === 'target') { applyTarget(); refresh(); } else runHint();
    }));
  });
}
function setSeg(name, v){ document.querySelectorAll('.seg[data-opt="'+name+'"] button').forEach(b => b.setAttribute('aria-pressed', b.dataset.v === v ? 'true' : 'false')); opts[name] = v; }
function invalidate(){ result = null; roms = null; fdd = null; ['dlDsk','dlZip','dlYAMA','dlA16X','dlD1','dlFddZip'].forEach(id => $(id).disabled = true); }
function runHint(){
  const t = opts.target, font = cls && cls.font;
  const run = t === 'cart' ? '한글 한자 ROM: 필요 없음 (글꼴이 카트리지 안에 들어감)'
    : t === 'fdd' ? '한글 한자 ROM: 필요 없음 (글꼴이 디스크 1에 들어감). 단, 512KB 매퍼 기계(FS-A1GT 등)일 때. 256KB 기계에서는 필요.'
    : opts.font === 'file' ? '한글 한자 ROM: 필요 없음 (글꼴을 ICITY\\FONT.BIN에서 읽음)'
    : '한글 한자 ROM: 필요 (실행하는 기계의 한글판 한자 ROM에서 글자를 읽음. 없으면 글자가 깨짐)';
  const make = t === 'dsk' ? (font ? '만들 때: 올린 KANJI.rom으로 FONT.BIN을 만듭니다.' : '만들 때: KANJI.rom을 올리면 FONT.BIN을 넣을 수 있습니다.')
    : '만들 때: KANJI.rom(키티야 님의 한글 한자 ROM 파일, 262144바이트)이 필요합니다. 글꼴을 가져오는 데만 씁니다.';
  $('runHint').textContent = run + ' · ' + make;
  $('fontHint').textContent = !font ? 'FONT.BIN을 쓰려면 KANJI.rom을 올리세요. 지금은 실행하는 기계에 한글 한자 ROM이 있어야 합니다.'
    : opts.font === 'file' ? '실행하는 기계에 한글 한자 ROM이 없어도 됩니다.' : '실행하는 기계에 한글 한자 ROM이 있어야 합니다(없으면 글자가 깨짐).';
}
function applyTarget(){
  document.querySelectorAll('#need tr[data-t]').forEach(r => r.classList.toggle('cur', r.dataset.t === opts.target));
  const cart = opts.target === 'cart', fl = opts.target === 'fdd', dsk = !cart && !fl;
  document.querySelectorAll('.dsk-only').forEach(r => { if (r.id === 'dosRow') r.hidden = !dsk || !(cls && cls.dos['MSXDOS2.SYS'] && cls.dos['NEXTOR.SYS']); else r.hidden = !dsk; });
  const en8 = !!(cls && cls.release === 'en8');
  $('fontRow').hidden = !dsk || en8; $('en8note').hidden = !en8;
  $('savesRow').hidden = fl;
  $('dlDsk').hidden = !dsk; $('dlZip').hidden = !dsk; $('dlYAMA').hidden = !cart; $('dlA16X').hidden = !cart; $('dlD1').hidden = !fl; $('dlFddZip').hidden = !fl;
  $('targetHint').textContent = cart ? '실행: 카트리지만 꽂고 켜면 시작합니다(디스크 드라이브·DOS 불필요).'
    : fl ? '실행: 원본처럼 플로피 8장(+ 유저 디스크)으로 실행합니다. 바뀌는 것은 디스크 1뿐입니다.'
    : '실행: MSX-DOS2(또는 Nextor)가 있는 하드디스크·SD 카드에서 ICITY.COM을 실행합니다.';
  runHint();
}

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
  const en8 = cls.release === 'en8', needFont = !en8 && opts.target !== 'dsk';
  chip('릴리스', en8 ? 'English 8-disc (MSX Translations)' : '한글판', 'ok');
  if (!en8) chip('KANJI.rom (글꼴)', cls.font ? '✓ ' + cls.font.name : needFont ? '없음 (필수)' : '없음 (선택)', cls.font ? 'ok' : needFont ? 'bad' : 'opt');
  const fddBtn = document.querySelector('.seg[data-opt="target"] button[data-v="fdd"]'); fddBtn.disabled = en8;
  if (en8 && opts.target === 'fdd') setSeg('target', 'dsk');
  const hasA = !!cls.dos['MSXDOS2.SYS'], hasN = !!cls.dos['NEXTOR.SYS'], hasC = !!cls.dos['COMMAND2.COM'];
  if (opts.target === 'dsk') {
    chip('MSXDOS2.SYS', hasA ? '✓' : '없음', hasA ? 'ok' : 'opt');
    chip('NEXTOR.SYS', hasN ? '✓' : '없음', hasN ? 'ok' : 'opt');
    chip('COMMAND2.COM', hasC ? '✓' : '없음', hasC ? 'ok' : 'opt');
  }
  slotList();
  const notes = $('notes'); if (cls.notes.length) { notes.hidden = false; notes.textContent = cls.notes.join('\n'); } else notes.hidden = true;
  // option availability
  $('fontFile').disabled = !cls.font || en8;
  if (!cls.font || en8) setSeg('font', 'rom');
  else if (opts.font === 'rom' && !$('fontFile').dataset.userRom && !en8) setSeg('font', 'file');
  $('dosRow').hidden = !(hasA && hasN);
  if (hasA && !hasN) opts.dos = 'ascii'; else if (hasN && !hasA) opts.dos = 'nextor';
  applyTarget();
  const ok = [1,2,3,4,5,6,7,8].every(n => cls.disks[n]);
  const cart = opts.target === 'cart', fl = opts.target === 'fdd';
  $('make').disabled = !ok || (!en8 && (cart || fl) && !cls.font);
  if (!ok) { if (items.length) show('bad', '게임 디스크 1~8이 모두 필요합니다. (디스크 라벨 IPROJ01~IPROJ08로 자동 인식합니다.)'); }
  else if (!en8 && cart && !cls.font) show('bad', '카트리지 ROM을 만들려면 KANJI.rom(키티야 님의 한글 한자 ROM 파일, 262144바이트)을 올려 주세요. 만든 카트리지는 한글 한자 ROM 없는 기계에서 실행됩니다.');
  else if (!en8 && fl && !cls.font) show('bad', '플로피판을 만들려면 KANJI.rom(키티야 님의 한글 한자 ROM 파일, 262144바이트)을 올려 주세요. 만든 디스크는 한글 한자 ROM 없는 기계에서 실행됩니다.');
  else if (!cart && !fl && !hasA && !hasN) show('warn', 'DOS 시스템 파일이 없습니다. 만들 수는 있지만 이미지만으로는 부팅되지 않습니다.');
}
function slotList(){
  const box = $('slots'); box.innerHTML = '';
  if (!cls || !cls.disks[1]) { box.hidden = true; return; }
  const one = (title, disk) => {
    let rows;
    try { rows = ICITY.saveSlots(cls.disks[1].data, disk); } catch (e) { return; }
    const d = document.createElement('div'), h = document.createElement('h3'), t = document.createElement('table');
    h.textContent = title; d.appendChild(h);
    t.innerHTML = '<tr><th class="num">NO</th><th class="num">LV</th><th>장소</th></tr>';
    for (const r of rows) {
      const tr = document.createElement('tr');
      [[r.n, 'num'], [r.valid ? r.lv : '--', 'num'], [r.valid ? r.place : '미등록', r.valid ? '' : 'e']].forEach(([v, c]) => { const td = document.createElement('td'); td.textContent = v; if (c) td.className = c; tr.appendChild(td); });
      t.appendChild(tr);
    }
    d.appendChild(t); box.appendChild(d);
  };
  one('디스크 1 세이브 (게임 목록과 같은 내용)', cls.disks[1].data);
  if (cls.user) one('유저 디스크 세이브: ' + cls.user.name, cls.user.data);
  box.hidden = !box.children.length;
}
function show(kind, text){ const m = $('msg'); m.className = kind === 'bad' ? 'bad' : kind === 'ok' ? 'ok' : ''; m.style.color = kind === 'warn' ? 'var(--warn)' : ''; m.textContent = text; }

async function make(){
  $('make').disabled = true; invalidate(); const log = $('log'); log.hidden = false; log.textContent = '';
  const L = m => { log.textContent += m + '\n'; log.scrollTop = log.scrollHeight; };
  show('', '만드는 중...');
  await new Promise(r => setTimeout(r, 30));
  try {
    if (opts.target === 'fdd') {
      fdd = ICITY.buildFdd({ assets: A, cls, log: L });
      $('dlD1').disabled = false; $('dlFddZip').disabled = false;
      show('ok', '완료: 바뀐 디스크 1(D1.dsk)만 받거나, 8장을 ZIP으로 받을 수 있습니다. 디스크 2~8과 유저 디스크는 원래 것을 그대로 쓰면 됩니다. 실행할 기계에 한글 한자 ROM이 필요 없습니다.');
      $('make').disabled = false; return;
    }
    if (opts.target === 'cart') {
      roms = ICITY.buildCart({ assets: A, cls, keepSaves: opts.saves === 'keep', log: L });
      $('dlYAMA').disabled = false; $('dlA16X').disabled = false;
      show('ok', cls.release === 'en8' ? 'Done: the cartridge ROMs (Yamanooto, ASCII16-X, 4MB each) can be downloaded; pick the one for your cartridge.' : '완료: 카트리지 ROM(Yamanooto, ASCII16-X, 각 4MB)을 내려받을 수 있습니다. 가지고 있는 카트리지 종류에 맞는 것을 고르세요. 실행할 기계에 한글 한자 ROM이 필요 없습니다.');
      $('make').disabled = false; return;
    }
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
    show('ok', cls.release === 'en8' ? 'Done: the hard-disk image (.hd.dsk) and the ZIP (SD card) can be downloaded.' : '완료: 하드디스크 이미지(.hd.dsk)와 ZIP을 내려받을 수 있습니다.' + (r.fontOn ? ' 실행할 기계에 한글 한자 ROM이 필요 없습니다(FONT.BIN).' : ' 이 설정으로는 한글 한자 ROM이 있는 기계에서만 글자가 나옵니다.'));
  } catch (e) { show('bad', '오류: ' + e.message); L('오류: ' + e.message); }
  $('make').disabled = false;
}
function save(name, bytes, type){
  const a = document.createElement('a'); a.href = URL.createObjectURL(new Blob([bytes], { type: type || 'application/octet-stream' })); a.download = name;
  document.body.appendChild(a); a.click(); setTimeout(() => { URL.revokeObjectURL(a.href); a.remove(); }, 4000);
}
segs(); applyTarget(); refresh();
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
$('dlDsk').addEventListener('click', () => result && save('ICITY' + (opts.autoexec === 'on' ? '_AUTO' : '') + '.hd.dsk', result.image));
$('dlZip').addEventListener('click', () => result && save('ICITY_SD.zip', ICITY.zipWrite(result.files), 'application/zip'));
$('dlD1').addEventListener('click', () => fdd && save('D1.dsk', fdd[0].data));
$('dlFddZip').addEventListener('click', () => fdd && save('ICITY_FDD.zip', ICITY.zipWrite(fdd.map(d => ({ path: 'I-City(k)(' + d.n + '-8).dsk', data: d.data }))), 'application/zip'));
['YAMA','A16X'].forEach(t => $('dl' + t).addEventListener('click', () => { const r = roms && roms.find(x => x.tag === t); if (r) save('ICITY_' + t + '.rom', r.rom); }));
})();
</script>
</body>
</html>
