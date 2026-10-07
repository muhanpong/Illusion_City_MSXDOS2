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
body{margin:0;background:var(--bg);color:var(--ink);font:15px/1.55 system-ui,-apple-system,"Segoe UI","Malgun Gothic","Apple SD Gothic Neo","Hiragino Sans","Yu Gothic",sans-serif}
main{max-width:760px;margin:0 auto;padding:14px 16px 48px}
.langs{display:flex;gap:4px;margin:0 0 10px;border-bottom:1px solid var(--line)}
.langs button{border:1px solid transparent;border-bottom:0;background:transparent;color:var(--mute);padding:6px 14px;font:inherit;font-size:14px;cursor:pointer;border-radius:8px 8px 0 0;margin-bottom:-1px}
.langs button:hover{color:var(--ink)}
.langs button[aria-selected="true"]{background:var(--card);color:var(--acc);border-color:var(--line);font-weight:600;box-shadow:inset 0 2px 0 var(--acc)}
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
.seg{display:inline-flex;flex-wrap:wrap;border:1px solid var(--line);border-radius:9px;overflow:hidden}
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
button.link{border:0;background:none;color:var(--acc);font:inherit;padding:0;cursor:pointer;text-decoration:underline}
#msg{margin-top:10px;font-size:14px}
#msg.bad{color:var(--bad)}#msg.ok{color:var(--ok)}
#relnote{border-left:3px solid var(--acc);padding:6px 10px;margin:12px 0 0;color:var(--ink);font-size:14px;background:color-mix(in srgb,var(--acc) 6%,transparent);border-radius:0 8px 8px 0}
pre{background:var(--bg);border:1px solid var(--line);border-radius:8px;padding:10px;font-size:12px;max-height:190px;overflow:auto;margin:10px 0 0;white-space:pre-wrap}
footer{color:var(--mute);font-size:12.5px;margin-top:14px}
.need{width:100%;border-collapse:collapse;font-size:13px;margin:0 0 16px}
.need th,.need td{border-bottom:1px solid var(--line);padding:6px 8px;text-align:left;vertical-align:top}
.need th{color:var(--mute);font-weight:600}
.need td.y{color:var(--ok);font-weight:600}.need td.n{color:var(--warn);font-weight:600}.need td.x{color:var(--mute)}
.need tr.cur td{background:color-mix(in srgb,var(--acc) 8%,transparent)}
.tbl{overflow-x:auto}
.slots{display:grid;grid-template-columns:repeat(auto-fit,minmax(260px,1fr));gap:10px;margin-top:12px}
.slots h3{font-size:13px;margin:0 0 4px;color:var(--mute);font-weight:600}
.slots table{width:100%;border-collapse:collapse;font-size:13px}
.slots td,.slots th{padding:3px 6px;border-bottom:1px solid var(--line);text-align:left}
.slots th{color:var(--mute);font-weight:600}.slots td.e{color:var(--mute)}.slots td.num{text-align:right;width:3em}
@media(max-width:520px){.row>label{min-width:100%}.langs button{padding:6px 10px}}
</style>
</head>
<body>
<main>
<nav class="langs" role="tablist" aria-label="Language">
  <button role="tab" data-lang="ko" aria-selected="true" title="한국어로 보기 — 한글판 디스크용" lang="ko">한국어</button><button role="tab" data-lang="en" aria-selected="false" title="View in English — for the English (MSX Translations) disks" lang="en">English</button><button role="tab" data-lang="ja" aria-selected="false" title="日本語で表示 — 日本語版ディスク用" lang="ja">日本語</button>
</nav>

<div data-lang="ko">
<h1>환영도시(ILLUSION CITY) HDD·ROM·플로피 만들기</h1>
<p class="sub">게임 디스크를 올리면 MSX-DOS2 하드디스크 이미지 <b>.hd.dsk</b>(또는 SD 카드에 복사할 ZIP), 꽂기만 하면 되는 <b>카트리지 ROM</b>(Yamanooto / ASCII16-X), 또는 한글 한자 ROM 없이 도는 <b>플로피</b>(원본 8장 중 디스크 1만 수정)를 만들어 줍니다. 모든 처리는 이 브라우저 안에서만 이뤄지고 파일은 어디로도 전송되지 않습니다.</p>
<div class="tbl"><table class="need">
<tr><th>만들 것</th><th>실행하는 방법</th><th>실행할 기계에 한글 한자 ROM</th><th>만들 때 KANJI.rom</th></tr>
<tr data-t="dsk"><td>DOS2 하드디스크 (HDD / SD)</td><td>MSX-DOS2·Nextor 하드디스크나 SD 카드에서 ICITY.COM</td><td class="y">필요 없음 (FONT.BIN을 넣을 때)<br><span style="color:var(--warn)">넣지 않으면 필요</span></td><td>선택 (FONT.BIN용)</td></tr>
<tr data-t="cart"><td>카트리지 ROM</td><td>Yamanooto·ASCII16-X 카트리지를 꽂고 켜기</td><td class="y">필요 없음</td><td>필수</td></tr>
<tr data-t="fdd"><td>플로피</td><td>원본처럼 디스크 8장 + 유저 디스크</td><td class="y">필요 없음<br><span style="color:var(--mute);font-weight:400">512KB 매퍼 기계. 256KB 기계는 필요</span></td><td>필수</td></tr>
</table></div>
<p class="sub" style="margin-top:-8px">KANJI.rom(262144바이트)은 키티야 님이 만드신 한글 한자 ROM 파일입니다. 만들 때 여기서 글꼴을 가져와 결과물에 넣을 뿐이고, 결과물을 실행하는 기계와는 상관없습니다.</p>
<p class="sub">이 도구와 여기서 만드는 결과물은 환영도시의 한글 번역과 한글 글꼴(KANJI.rom), 인코딩 작업을 해 주신 <b>키티야 님</b>께 감사의 마음을 담아 드립니다. 화면에 나오는 한글은 모두 키티야 님의 작업입니다. (<a href="https://blog.naver.com/kkitty5425/222619726741" target="_blank" rel="noopener">키티야 님의 환영도시 한글화 글</a>)</p>
</div>

<div data-lang="en" hidden>
<h1>Illusion City HDD / ROM builder</h1>
<p class="sub">Drop the game disks of the <b>English 8-disk release</b> (translation by MSX Translations) and get an MSX-DOS2 hard-disk image <b>.hd.dsk</b> (or a ZIP to copy to an SD card), or a plug-and-play <b>cartridge ROM</b> (Yamanooto / ASCII16-X). Everything happens inside this browser; no file is sent anywhere.</p>
<div class="tbl"><table class="need">
<tr><th>Output</th><th>How to run it</th><th>Kanji ROM in the machine</th><th>Needed to build</th></tr>
<tr data-t="dsk"><td>DOS2 hard disk (HDD / SD)</td><td>ICITY.COM from an MSX-DOS2 or Nextor hard disk / SD card</td><td class="y">not needed</td><td>the 8 game disks (+ DOS files)</td></tr>
<tr data-t="cart"><td>Cartridge ROM</td><td>insert a Yamanooto or ASCII16-X cartridge and switch on</td><td class="y">not needed</td><td>the 8 game disks</td></tr>
<tr data-t="fdd"><td>Floppy</td><td class="x" colspan="3">not offered: the English game runs from its original disks as it is</td></tr>
</table></div>
<p class="sub">English translation: <b>MSX Translations</b> — patch and details on their page: <a href="https://msxtranslations.com/ic.php" target="_blank" rel="noopener">msxtranslations.com/ic.php</a> (apply the IPS patches to the eight Japanese disks; their own ROM version is built there as well). This tool only repackages their work so it can be played from a hard disk, an SD card or a cartridge. The tool itself was first made for the Korean translation by Kittya (see the Korean tab).</p>
</div>

<div data-lang="ja" hidden>
<h1>幻影都市(ILLUSION CITY) HDD・ROM作成ツール</h1>
<p class="sub"><b>日本語版(オリジナル)</b>のゲームディスクを入れると、MSX-DOS2 ハードディスクイメージ <b>.hd.dsk</b>(SDカード用ZIPも可)、または挿すだけで遊べる<b>カートリッジROM</b>(Yamanooto / ASCII16-X)を作ります。処理はすべてこのブラウザの中だけで行われ、ファイルはどこにも送信されません。</p>
<div class="tbl"><table class="need">
<tr><th>作るもの</th><th>実行のしかた</th><th>実行する機械の漢字ROM</th><th>作成時の漢字ROMファイル</th></tr>
<tr data-t="dsk"><td>DOS2 ハードディスク (HDD / SD)</td><td>MSX-DOS2・Nextor のハードディスクやSDカードから ICITY.COM</td><td class="y">不要(FONT.BIN を入れた場合)<br><span style="color:var(--warn)">入れない場合は必要</span></td><td>任意(FONT.BIN用)</td></tr>
<tr data-t="cart"><td>カートリッジROM</td><td>Yamanooto・ASCII16-X カートリッジを挿して電源を入れる</td><td class="y">不要(漢字ROMファイルを入れた場合)<br><span style="color:var(--warn)">入れない場合は必要</span></td><td>任意(ROM内フォント用)</td></tr>
<tr data-t="fdd"><td>フロッピー</td><td class="x" colspan="3">対象外:日本語版は元のディスクのまま漢字ROMのある機械で動きます</td></tr>
</table></div>
<p class="sub" style="margin-top:-8px">漢字ROMファイル(262144バイト)は、お持ちの MSX(FS-A1GT など)の漢字ROMを吸い出したものです。なくても作れます(そのときは実行する機械の漢字ROMで表示)。入れると結果の中にフォントが入り、漢字ROMのない環境でも動きます。</p>
<p class="sub">原作:マイクロキャビン(1991)。このツールは、キティヤさんによる韓国語版のために作ったものを日本語版でも使えるようにしたものです。</p>
</div>

<section>
<h2><span class="n">1</span><span data-i="s1"></span></h2>
<div id="drop" tabindex="0" role="button">
  <b data-i="dropMain"></b>
  <small data-i="dropSmall"></small>
</div>
<input id="pick" type="file" multiple hidden>
<div class="checks" id="checks"></div>
<div class="slots" id="slots" hidden></div>
<pre id="notes" hidden></pre>
<p id="relnote" hidden></p>
</section>

<section>
<h2><span class="n">2</span><span data-i="s2"></span></h2>
<div class="row"><label data-i="lTarget"></label>
  <div class="seg" data-opt="target"><button data-v="dsk" aria-pressed="true" data-i="tDsk"></button><button data-v="cart" data-i="tCart"></button><button data-v="fdd" data-i="tFdd"></button></div>
  <div class="hint" id="targetHint"></div>
  <div class="hint" id="runHint"></div></div>
<div class="row dsk-only"><label data-i="lAuto"></label>
  <div class="seg" data-opt="autoexec"><button data-v="on" data-i="autoOn"></button><button data-v="off" aria-pressed="true" data-i="autoOff"></button></div>
  <div class="hint" data-i="autoHint"></div></div>
<div class="row dsk-only" id="fontRow"><label data-i="lFont"></label>
  <div class="seg" data-opt="font"><button data-v="file" id="fontFile" disabled></button><button data-v="rom" aria-pressed="true" id="fontRom"></button></div>
  <div class="hint" id="fontHint"></div></div>
<div class="row cart-only" id="padRow" hidden><label data-i="lPad"></label>
  <div class="seg" data-opt="pad8"><button data-v="off" aria-pressed="true" data-i="pad4"></button><button data-v="on" data-i="pad8"></button></div>
  <div class="hint" data-i="padHint"></div></div>
<div class="row" id="savesRow"><label data-i="lSaves"></label>
  <div class="seg" data-opt="saves"><button data-v="keep" aria-pressed="true" data-i="savesKeep"></button><button data-v="blank" data-i="savesBlank"></button></div></div>
<div class="row dsk-only" id="dosRow" hidden><label data-i="lDos"></label>
  <div class="seg" data-opt="dos"><button data-v="ascii" aria-pressed="true">ASCII DOS2</button><button data-v="nextor">Nextor</button></div>
  <div class="hint" data-i="dosHint"></div></div>
<div class="row dsk-only"><label data-i="lReadme"></label>
  <div class="seg" data-opt="readme"><button data-v="on" aria-pressed="true" data-i="readmeOn"></button><button data-v="off" data-i="readmeOff"></button></div></div>
<div class="row dsk-only"><label data-i="lVolume"></label><input id="label" type="text" value="ICITYDOS2" maxlength="11" spellcheck="false"></div>
</section>

<section>
<h2><span class="n">3</span><span data-i="s3"></span></h2>
<div class="go">
  <button class="primary" id="make" disabled data-i="make"></button>
  <button class="dl" id="dlDsk" disabled data-i="dlDsk"></button>
  <button class="dl" id="dlZip" disabled data-i="dlZip"></button>
  <button class="dl" id="dlYAMA" disabled hidden data-i="dlYAMA"></button>
  <button class="dl" id="dlA16X" disabled hidden data-i="dlA16X"></button>
  <button class="dl" id="dlD1" disabled hidden data-i="dlD1"></button>
  <button class="dl" id="dlFddZip" disabled hidden data-i="dlFddZip"></button>
</div>
<div id="msg"></div>
<pre id="log" hidden></pre>
</section>

<footer data-lang="ko">
도구 버전 2026-10-03 — 영어판(MSX Translations 8장)·일본어판도 만들 수 있게 됐습니다(위 언어 탭). 한글판 결과물은 2026-10-01 판과 같습니다. 2026-10-01 이전에 만든 한글판 DOS2·카트리지 결과물은 한자 ROM 없는 기계에서 엔딩 인트로 글자가 깨지므로 다시 만들어 주세요.<br>
HDD: 16MB FAT12 하드디스크 이미지(헤더 없는 원시 섹터 이미지). openMSX: IDE·Nextor 확장을 붙이고 <code>hda ICITY.hd.dsk</code>(openMSX도 하드디스크를 hd.dsk로 부름). MiSTer: 내용이 같으므로 확장자만 <code>.vhd</code>로 바꿔 쓰세요. ZIP: 안의 ICITY.COM 과 ICITY 폴더를 SD 카드 루트에 복사하세요.
ROM: 내용 4MB(4MB 이상 플래시의 Yamanooto 또는 ASCII16-X 카트리지용, 매퍼마다 파일 하나, 만드는 데 몇십 초). ASCII16-X 파일에는 0010h에 "ASCII16X" 서명이 있어 openMSX와 MiSTer 코어(매퍼 auto)가 플래시 매퍼로 인식합니다. 카트리지만 꽂고 켜면 시작하고, 한글은 ROM 안의 글꼴로 나오며(실행하는 기계에 한글 한자 ROM 불필요), 디스크 1·유저 디스크 슬롯 세이브는 카트리지 플래시에 기록됩니다. openMSX: <code>-carta ICITY_YAMA.rom -romtype Yamanooto</code>.
플로피: 디스크 1의 빈 섹터(550h~)에 게임이 쓰는 글자 1395자만 압축해 넣고, 한자 ROM 대신 그 글꼴을 읽게 합니다. FM·MIDI 모두 동작합니다.
<b>실행할 기계에 한글 한자 ROM이 필요한가</b> — HDD + FONT.BIN: 필요 없음 · HDD + 기계의 한자 ROM: 필요 · 카트리지: 필요 없음 · 플로피: 필요 없음(512KB 매퍼 기계. 256KB 기계에서는 필요).
<b>만들 때의 KANJI.rom</b>은 키티야 님이 만드신 한글 한자 ROM 파일로, 여기서 글꼴을 가져와 결과물에 넣는 데만 씁니다. 결과물을 실행하는 기계와는 상관없습니다.
한글 번역·한글 글꼴·인코딩: 키티야 님 (<a href="https://blog.naver.com/kkitty5425/222619726741" target="_blank" rel="noopener">한글화 글</a>). 이 도구는 그 작업을 여러 방식으로 즐길 수 있게 옮기는 도구입니다.
게임 데이터·DOS 파일·폰트는 앱에 들어 있지 않습니다. 앱에는 런처(ICITY.COM), 부트 섹터, 카트리지 부트 코드, 플로피 패치 코드만 들어 있습니다.
</footer>
<footer data-lang="en" hidden>
Tool version 2026-10-03 — adds the English 8-disk release (MSX Translations) and the Japanese original.<br>
HDD: a 16MB FAT12 hard-disk image (raw sectors, no header). openMSX: add an IDE / Nextor extension and <code>hda ICITY.hd.dsk</code>. MiSTer: same content, just rename it to <code>.vhd</code>. ZIP: copy ICITY.COM and the ICITY folder to the root of the SD card. The English DOS2 version has 96 save slots per disk (left/right on the slot list, keyboard or joystick).
ROM: 4MB of content, for a Yamanooto or ASCII16-X cartridge with 4MB or more of flash (one file per mapper; building takes some tens of seconds). The ASCII16-X file carries the "ASCII16X" signature at 0010h, so openMSX and the MiSTer core (mapper auto) pick the flash mapper. Insert the cartridge and switch on; disk 1 and user-disk saves are written to the cartridge's flash. openMSX: <code>-carta ICITY_YAMA.rom -romtype Yamanooto</code>.
A user disk is optional; a Japanese "Data Disk" works as one (same save format).
English translation: MSX Translations (<a href="https://msxtranslations.com/ic.php" target="_blank" rel="noopener">translation page</a>). No game data, DOS files or fonts are inside this page: it carries only the launchers (ICITY.COM), a boot sector and the cartridge boot code.
</footer>
<footer data-lang="ja" hidden>
ツールのバージョン 2026-10-03 — 英語版(MSX Translations 8枚)と日本語版に対応しました。<br>
HDD:16MB の FAT12 ハードディスクイメージ(ヘッダなしの生セクタ)。openMSX:IDE・Nextor 拡張を付けて <code>hda ICITY.hd.dsk</code>。MiSTer:中身は同じなので拡張子を <code>.vhd</code> に変えるだけです。ZIP:中の ICITY.COM と ICITY フォルダをSDカードのルートにコピーしてください。セーブはディスクごとに96スロット(スロット一覧で左右キーまたはジョイスティック)。
ROM:中身4MB(4MB以上のフラッシュを持つ Yamanooto または ASCII16-X カートリッジ用、マッパーごとに1ファイル、作成に数十秒)。ASCII16-X のファイルは 0010h に "ASCII16X" の署名があり、openMSX と MiSTer コア(マッパー auto)がフラッシュマッパーとして認識します。カートリッジを挿して電源を入れるだけで始まります。漢字ROMファイルを入れて作った場合は文字をROM内のフォントで表示し(実行する機械に漢字ROM不要)、入れずに作った場合は機械の漢字ROMを使います。ディスク1・ユーザーディスクのセーブはカートリッジのフラッシュに書き込まれます。openMSX:<code>-carta ICITY_YAMA.rom -romtype Yamanooto</code>。
「データディスク1〜4」はユーザーディスクとしてそのまま使えます。ゲームデータ・DOSファイル・フォントはこのページに含まれていません。含まれているのはランチャー(ICITY.COM)、ブートセクタ、カートリッジのブートコードだけです。
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
const opts = { target:'dsk', autoexec:'off', font:'rom', saves:'keep', dos:'ascii', readme:'on', pad8:'off' };
let items = [], cls = null, result = null, roms = null, fdd = null, lang = 'ko';
const REL_OF = { ko:'ko', en:'en8', ja:'ja' }, LANG_OF = { ko:'ko', en8:'en', ja:'ja' };

/* ---------------------------------------------------------------- texts: static labels (data-i) and messages, per page language */
const T = {
ko: { tabs:['한국어','영어','일본어'], title:'환영도시 HDD·ROM·플로피 만들기', s1:'파일 올리기', s2:'옵션', s3:'만들기',
  dropMain:'여기로 파일을 끌어다 놓거나 눌러서 선택', dropSmall:'게임 디스크 8장(.dsk 또는 zip) · 유저 디스크(선택, 최대 12장: 파일 이름 순으로 세이브 목록 1~12페이지) · KANJI.rom(카트리지·플로피는 필수, HDD는 선택) · MSXDOS2.SYS + COMMAND2.COM 또는 NEXTOR.SYS (HDD만, zip 가능)',
  lTarget:'만들 것', tDsk:'DOS2 하드디스크 (HDD / SD)', tCart:'카트리지 ROM', tFdd:'플로피 (원본 디스크 8장)',
  lAuto:'시작할 때 자동 실행', autoOn:'AUTOEXEC.BAT 사용', autoOff:'사용 안 함', autoHint:'켜면 부팅하자마자 ICITY를 실행합니다. 런처 오류 메시지가 순식간에 지나갈 수 있어 처음에는 끄는 것을 권합니다.',
  lFont:'실행할 때 글자', lSaves:'세이브', savesKeep:'올린 유저 디스크의 세이브 유지', savesBlank:'빈 세이브로 시작', lDos:'DOS 종류', dosHint:'두 종류의 파일이 모두 올라와 있어 선택합니다.',
  lReadme:'README.TXT 포함', readmeOn:'포함', readmeOff:'제외', lVolume:'볼륨 이름',
  lPad:'ASCII16-X 파일 크기', pad4:'4MB (MiSTer 매퍼 auto)', pad8:'8MB (MiSTer OSD에서 ASCII16X 직접 선택)',
  padHint:'MiSTer에서 OSD 매퍼를 auto로 두면 4MB 파일을 서명으로 알아봅니다. 매퍼를 ASCII16X로 직접 고르면 코어가 4MB보다 큰 파일만 플래시로 받으므로 8MB를 고르세요. 내용은 같고 뒤를 FFh로 채운 것입니다(Yamanooto 파일은 그대로 4MB).',
  make:'만들기', dlDsk:'하드디스크 이미지 내려받기 (.hd.dsk)', dlZip:'ZIP 내려받기 (SD 카드용)', dlYAMA:'Yamanooto ROM 내려받기', dlA16X:'ASCII16-X ROM 내려받기', dlD1:'디스크 1 내려받기 (D1.dsk)', dlFddZip:'ZIP 내려받기 (디스크 8장)',
  disk:n => '게임 디스크 ' + n, none:'없음', user:'유저 디스크', userNone:'없음(빈 세이브)', rel:'판', relName:{ ko:'한글판', ja:'일본어판', en8:'영어판 (MSX Translations)', en6:'영어 6장판 (지원 안 함)' },
  font:'글꼴 파일', req:'없음 (필수)', opt:'없음 (선택)',
  romName:{ ko:'한글 한자 ROM', ja:'한자 ROM(일본어)' }, fileName:{ ko:'KANJI.rom(키티야 님의 한글 한자 ROM 파일, 262144바이트)', ja:'일본어 한자 ROM 파일(262144바이트, 기계에서 덤프한 것)' },
  fontFile:r => 'FONT.BIN (' + T.ko.romName[r] + ' 불필요)', fontRom:r => '기계의 ' + T.ko.romName[r],
  tHint:{ cart:'실행: 카트리지만 꽂고 켜면 시작합니다(디스크 드라이브·DOS 불필요).', fdd:'실행: 원본처럼 플로피 8장(+ 유저 디스크)으로 실행합니다. 바뀌는 것은 디스크 1뿐입니다.', dsk:'실행: MSX-DOS2(또는 Nextor)가 있는 하드디스크·SD 카드에서 ICITY.COM을 실행합니다.' },
  runCart:(r, f) => r === 'ja' && !f ? T.ko.runRom(r) : r === 'en8' ? '한자 ROM: 필요 없음' : T.ko.romName[r] + ': 필요 없음 (글꼴이 카트리지 안에 들어감)',
  runFdd:'한글 한자 ROM: 필요 없음 (글꼴이 디스크 1에 들어감). 단, 512KB 매퍼 기계(FS-A1GT 등)일 때. 256KB 기계에서는 필요.',
  runFile:r => T.ko.romName[r] + ': 필요 없음 (글꼴을 ICITY\\FONT.BIN에서 읽음)', runRom:r => r === 'en8' ? '한자 ROM: 필요 없음 (영어판은 한자 ROM을 쓰지 않음)' : T.ko.romName[r] + ': 필요 (실행하는 기계의 ' + T.ko.romName[r] + '에서 글자를 읽음. 없으면 글자가 깨짐)',
  makeDsk:(r, f) => r === 'en8' ? '만들 때: 게임 디스크 8장만 있으면 됩니다.' : f ? '만들 때: 올린 글꼴 파일로 FONT.BIN을 만듭니다.' : '만들 때: ' + T.ko.fileName[r] + '을 올리면 FONT.BIN을 넣을 수 있습니다.',
  makeCartJa:'만들 때: 한자 ROM 파일은 선택입니다. 넣으면 글꼴이 카트리지 안에 들어가고, 없으면 실행하는 기계의 한자 ROM을 씁니다.',
  makeNeed:r => r === 'en8' ? '만들 때: 게임 디스크 8장만 있으면 됩니다.' : '만들 때: ' + T.ko.fileName[r] + '이 필요합니다. 글꼴을 가져오는 데만 씁니다.',
  fontHintNo:r => 'FONT.BIN을 쓰려면 ' + T.ko.fileName[r] + '을 올리세요. 지금은 실행하는 기계에 ' + T.ko.romName[r] + '이 있어야 합니다.',
  fontHintFile:r => '실행하는 기계에 ' + T.ko.romName[r] + '이 없어도 됩니다.', fontHintRom:r => '실행하는 기계에 ' + T.ko.romName[r] + '이 있어야 합니다(없으면 글자가 깨짐).',
  needDisks:'게임 디스크 1~8이 모두 필요합니다. (디스크 라벨 IPROJ01~IPROJ08로 자동 인식합니다.)',
  needFont:(r, w) => (w === 'cart' ? '카트리지 ROM' : '플로피판') + '을 만들려면 ' + T.ko.fileName[r] + '을 올려 주세요. 만든 결과물은 ' + T.ko.romName[r] + ' 없는 기계에서 실행됩니다.',
  noDos:'DOS 시스템 파일이 없습니다. 만들 수는 있지만 이미지만으로는 부팅되지 않습니다.', en6:'영어 6장판은 지원하지 않습니다. MSX Translations의 8장판을 올려 주세요.',
  other:(r, l) => '올린 디스크는 ' + T.ko.relName[r] + '입니다. ', otherGo:l => T.ko.tabs[['ko','en','ja'].indexOf(l)] + ' 탭으로 보기',
  relNote:{ en8:'영어판(번역: MSX Translations)입니다. 게임 디스크 8장만 있으면 되고(유저 디스크는 선택, 일본어판 "Data Disk"도 유저 디스크로 쓸 수 있음) 한자 ROM·글꼴 파일이 필요 없습니다. 플로피판은 만들지 않습니다.',
    ja:'일본어판입니다. 글꼴은 일본어 한자 ROM이며, 보통 기계에 들어 있는 그 ROM을 그대로 씁니다. 한자 ROM 파일(262144바이트)은 선택: 넣으면 결과물 안에 글꼴이 들어가 한자 ROM 없는 환경에서도 돕니다. 플로피판은 만들지 않습니다(원본 디스크 그대로 동작).' },
  slotHead:['NO','LV','장소'], slotEmpty:'미등록', slotD1:'디스크 1 세이브 (게임 목록과 같은 내용)', slotU:(n, k, m) => m > 1 ? '유저 디스크 ' + k + ' (세이브 목록 ' + k + '페이지, 슬롯 ' + (8 * k - 7) + '~' + 8 * k + '): ' + n : '유저 디스크 세이브: ' + n,
  users:n => n + '장 (페이지 1~' + n + ')',
  busy:'만드는 중...', err:'오류: ', doneFdd:'완료: 바뀐 디스크 1(D1.dsk)만 받거나, 8장을 ZIP으로 받을 수 있습니다. 디스크 2~8과 유저 디스크는 원래 것을 그대로 쓰면 됩니다. 실행할 기계에 한글 한자 ROM이 필요 없습니다.',
  doneCart:(r, f) => '완료: 카트리지 ROM(Yamanooto, ASCII16-X, 각 4MB)을 내려받을 수 있습니다. 가지고 있는 카트리지 종류에 맞는 것을 고르세요.' + (r === 'en8' ? '' : f ? ' 실행할 기계에 ' + T.ko.romName[r] + '이 필요 없습니다.' : ' 실행하는 기계의 ' + T.ko.romName[r] + '으로 글자를 냅니다.'),
  doneDsk:(r, f) => '완료: 하드디스크 이미지(.hd.dsk)와 ZIP을 내려받을 수 있습니다.' + (r === 'en8' ? '' : f ? ' 실행할 기계에 ' + T.ko.romName[r] + '이 필요 없습니다(FONT.BIN).' : ' 이 설정으로는 ' + T.ko.romName[r] + '이 있는 기계에서만 글자가 나옵니다.'),
  files:(n, u, t, mb) => '파일 ' + n + '개, 사용 클러스터 ' + u + '/' + t + ' (여유 ' + mb + 'MB)', zip:'이 브라우저는 zip 해제를 지원하지 않습니다. 압축을 풀어서 올려 주세요. (Chrome/Edge/Firefox/Safari 최신 버전)' },

en: { tabs:['Korean','English','Japanese'], title:'Illusion City HDD / ROM builder', s1:'Add files', s2:'Options', s3:'Build',
  dropMain:'Drop files here or click to choose', dropSmall:'the 8 game disks (.dsk or zip) · user disks (optional, up to 12: in file-name order, pages 1-12 of the save list) · MSXDOS2.SYS + COMMAND2.COM or NEXTOR.SYS (HDD only, zip OK). Korean / Japanese releases: a 256KB Kanji ROM file as well (see their tabs)',
  lTarget:'Output', tDsk:'DOS2 hard disk (HDD / SD)', tCart:'Cartridge ROM', tFdd:'Floppy (Korean release only)',
  lAuto:'Run at boot', autoOn:'use AUTOEXEC.BAT', autoOff:'off', autoHint:'Starts ICITY right after booting. Leave it off at first: launcher error messages may flash by too fast to read.',
  lFont:'Text at run time', lSaves:'Saves', savesKeep:'keep the saves of the user disk', savesBlank:'start with empty saves', lDos:'DOS', dosHint:'Both kinds of DOS files were added; pick one.',
  lReadme:'Include README.TXT', readmeOn:'yes', readmeOff:'no', lVolume:'Volume name',
  lPad:'ASCII16-X file size', pad4:'4MB (MiSTer mapper auto)', pad8:'8MB (MiSTer OSD mapper set to ASCII16X)',
  padHint:'With the MiSTer OSD mapper on auto, the 4MB file is recognised by its signature. If you pick ASCII16X by hand, the core takes the file as flash only when it is larger than 4MB: choose 8MB. Same content, padded with FFh (the Yamanooto file stays 4MB).',
  make:'Build', dlDsk:'Download hard-disk image (.hd.dsk)', dlZip:'Download ZIP (SD card)', dlYAMA:'Download Yamanooto ROM', dlA16X:'Download ASCII16-X ROM', dlD1:'Download disk 1 (D1.dsk)', dlFddZip:'Download ZIP (8 disks)',
  disk:n => 'Game disk ' + n, none:'missing', user:'User disk', userNone:'none (empty saves)', rel:'Release', relName:{ ko:'Korean', ja:'Japanese', en8:'English (MSX Translations)', en6:'English 6-disk (not supported)' },
  font:'Font file', req:'missing (required)', opt:'none (optional)',
  romName:{ ko:'Korean Kanji ROM', ja:'Kanji ROM' }, fileName:{ ko:'KANJI.rom (Kittya\'s Korean Kanji ROM file, 262144 bytes)', ja:'a Kanji ROM file (262144 bytes, dumped from a Japanese MSX)' },
  fontFile:r => 'FONT.BIN (no ' + T.en.romName[r] + ' needed)', fontRom:r => 'the machine\'s ' + T.en.romName[r],
  tHint:{ cart:'Run: insert the cartridge and switch on (no disk drive, no DOS).', fdd:'Run: from the 8 floppies (+ user disk) as the original; only disk 1 changes.', dsk:'Run: ICITY.COM from a hard disk or SD card with MSX-DOS2 (or Nextor).' },
  runCart:(r, f) => r === 'ja' && !f ? T.en.runRom(r) : r === 'en8' ? 'Kanji ROM: not needed' : T.en.romName[r] + ': not needed (the font is inside the cartridge)',
  runFdd:'Korean Kanji ROM: not needed (the font goes onto disk 1), on a 512KB-mapper machine (FS-A1GT etc.); a 256KB machine needs it.',
  runFile:r => T.en.romName[r] + ': not needed (the font is read from ICITY\\FONT.BIN)', runRom:r => r === 'en8' ? 'Kanji ROM: not needed (the English game does not use it)' : T.en.romName[r] + ': needed (the text is read from the machine\'s ' + T.en.romName[r] + '; garbled without it)',
  makeDsk:(r, f) => r === 'en8' ? 'To build: just the 8 game disks.' : f ? 'To build: FONT.BIN is made from the font file you added.' : 'To build: add ' + T.en.fileName[r] + ' to include FONT.BIN.',
  makeCartJa:'To build: a Kanji ROM file is optional. Added, its font goes into the cartridge; without it the machine\'s Kanji ROM is used.',
  makeNeed:r => r === 'en8' ? 'To build: just the 8 game disks.' : 'To build: ' + T.en.fileName[r] + ' is required (only its font is used).',
  fontHintNo:r => 'Add ' + T.en.fileName[r] + ' to use FONT.BIN. As it is, the machine needs a ' + T.en.romName[r] + '.',
  fontHintFile:r => 'The machine does not need a ' + T.en.romName[r] + '.', fontHintRom:r => 'The machine needs a ' + T.en.romName[r] + ' (text is garbled without it).',
  needDisks:'All 8 game disks are needed (recognised by their labels IPROJ01-IPROJ08).',
  needFont:(r, w) => 'To build the ' + (w === 'cart' ? 'cartridge ROM' : 'floppy version') + ', add ' + T.en.fileName[r] + '. The result runs on machines without a ' + T.en.romName[r] + '.',
  noDos:'No DOS system files: the image can be built but will not boot by itself.', en6:'The 6-disk English translation is not supported; please use the 8-disk MSX Translations release.',
  other:r => 'The disks you added are the ' + T.en.relName[r] + ' release. ', otherGo:l => 'Show the ' + T.en.tabs[['ko','en','ja'].indexOf(l)] + ' tab',
  relNote:{ en8:'English release (translation by MSX Translations): only the 8 game disks are needed (a user disk is optional; a Japanese "Data Disk" works as one). No Kanji ROM and no font file are needed, and the floppy version is not offered.',
    ja:'Japanese release: its font is the standard Japanese Kanji ROM that the machine normally has. A Kanji ROM file (262144 bytes) is optional: added, the font goes into the output and it also runs without a Kanji ROM. No floppy version (the original disks work as they are).' },
  slotHead:['NO','LV','Place'], slotEmpty:'empty', slotD1:'Disk 1 saves (as listed in the game)', slotU:(n, k, m) => m > 1 ? 'User disk ' + k + ' (save list page ' + k + ', slots ' + (8 * k - 7) + '-' + 8 * k + '): ' + n : 'User disk saves: ' + n,
  users:n => n + ' (pages 1-' + n + ')',
  busy:'Building...', err:'Error: ', doneFdd:'Done: download the changed disk 1 (D1.dsk) or all 8 disks as a ZIP. Disks 2-8 and the user disk stay as they are. No Korean Kanji ROM needed.',
  doneCart:(r, f) => 'Done: the cartridge ROMs (Yamanooto, ASCII16-X, 4MB each) can be downloaded; pick the one for your cartridge.' + (r === 'en8' ? '' : f ? ' The machine needs no ' + T.en.romName[r] + '.' : ' The text comes from the machine\'s ' + T.en.romName[r] + '.'),
  doneDsk:(r, f) => 'Done: the hard-disk image (.hd.dsk) and the ZIP (SD card) can be downloaded.' + (r === 'en8' ? '' : f ? ' The machine needs no ' + T.en.romName[r] + ' (FONT.BIN).' : ' With this setting the text only shows on a machine with a ' + T.en.romName[r] + '.'),
  files:(n, u, t, mb) => n + ' files, clusters used ' + u + '/' + t + ' (' + mb + 'MB free)', zip:'This browser cannot unpack zip files. Please unzip them first (current Chrome/Edge/Firefox/Safari can).' },

ja: { tabs:['韓国語','英語','日本語'], title:'幻影都市 HDD・ROM作成ツール', s1:'ファイルを入れる', s2:'オプション', s3:'作成',
  dropMain:'ここにファイルをドロップ、またはクリックして選択', dropSmall:'ゲームディスク8枚(.dsk または zip)・ユーザーディスク(任意、最大12枚:ファイル名順にセーブ一覧の1〜12ページ)・漢字ROMファイル(256KB、任意)・MSXDOS2.SYS + COMMAND2.COM または NEXTOR.SYS(HDDのみ、zip可)',
  lTarget:'作るもの', tDsk:'DOS2 ハードディスク (HDD / SD)', tCart:'カートリッジROM', tFdd:'フロッピー(韓国語版のみ)',
  lAuto:'起動時に自動実行', autoOn:'AUTOEXEC.BAT を使う', autoOff:'使わない', autoHint:'オンにすると起動直後に ICITY を実行します。ランチャーのエラーメッセージが一瞬で消えることがあるので、最初はオフをおすすめします。',
  lFont:'実行時の文字', lSaves:'セーブ', savesKeep:'入れたユーザーディスクのセーブを残す', savesBlank:'空のセーブで始める', lDos:'DOS の種類', dosHint:'両方の DOS ファイルがあるので選んでください。',
  lReadme:'README.TXT を入れる', readmeOn:'入れる', readmeOff:'入れない', lVolume:'ボリューム名',
  lPad:'ASCII16-X ファイルのサイズ', pad4:'4MB(MiSTer マッパー auto)', pad8:'8MB(MiSTer OSD で ASCII16X を直接選ぶ場合)',
  padHint:'MiSTer の OSD でマッパーを auto にすると、4MB のファイルを署名で認識します。マッパーを ASCII16X に直接設定すると、コアは 4MB より大きいファイルしかフラッシュとして扱わないので 8MB を選んでください。中身は同じで、後ろを FFh で埋めたものです(Yamanooto のファイルは 4MB のまま)。',
  make:'作成', dlDsk:'ハードディスクイメージをダウンロード (.hd.dsk)', dlZip:'ZIP をダウンロード (SDカード用)', dlYAMA:'Yamanooto ROM をダウンロード', dlA16X:'ASCII16-X ROM をダウンロード', dlD1:'ディスク1をダウンロード (D1.dsk)', dlFddZip:'ZIP をダウンロード (ディスク8枚)',
  disk:n => 'ゲームディスク ' + n, none:'なし', user:'ユーザーディスク', userNone:'なし(空のセーブ)', rel:'版', relName:{ ko:'韓国語版', ja:'日本語版', en8:'英語版 (MSX Translations)', en6:'英語6枚版(未対応)' },
  font:'フォントファイル', req:'なし(必須)', opt:'なし(任意)',
  romName:{ ko:'韓国語漢字ROM', ja:'漢字ROM' }, fileName:{ ko:'KANJI.rom(キティヤさんの韓国語漢字ROMファイル、262144バイト)', ja:'漢字ROMファイル(262144バイト、実機から吸い出したもの)' },
  fontFile:r => 'FONT.BIN(' + T.ja.romName[r] + '不要)', fontRom:r => '機械の' + T.ja.romName[r],
  tHint:{ cart:'実行:カートリッジを挿して電源を入れるだけです(ディスクドライブ・DOS 不要)。', fdd:'実行:元と同じくフロッピー8枚(+ユーザーディスク)で。変わるのはディスク1だけです。', dsk:'実行:MSX-DOS2(または Nextor)のハードディスク・SDカードから ICITY.COM を実行します。' },
  runCart:(r, f) => r === 'ja' && !f ? T.ja.runRom(r) : r === 'en8' ? '漢字ROM:不要' : T.ja.romName[r] + ':不要(フォントはカートリッジ内)',
  runFdd:'韓国語漢字ROM:不要(フォントはディスク1に入る)。512KBマッパーの機械(FS-A1GT など)の場合。256KBの機械では必要。',
  runFile:r => T.ja.romName[r] + ':不要(フォントを ICITY\\FONT.BIN から読む)', runRom:r => r === 'en8' ? '漢字ROM:不要(英語版は漢字ROMを使いません)' : T.ja.romName[r] + ':必要(実行する機械の' + T.ja.romName[r] + 'から文字を読みます。ないと文字化け)',
  makeDsk:(r, f) => r === 'en8' ? '作成時:ゲームディスク8枚だけで作れます。' : f ? '作成時:入れたフォントファイルから FONT.BIN を作ります。' : '作成時:' + T.ja.fileName[r] + 'を入れると FONT.BIN を入れられます。',
  makeCartJa:'作成時:漢字ROMファイルは任意です。入れるとフォントがカートリッジ内に入り、なければ実行する機械の漢字ROMを使います。',
  makeNeed:r => r === 'en8' ? '作成時:ゲームディスク8枚だけで作れます。' : '作成時:' + T.ja.fileName[r] + 'が必要です(フォントを取り出すだけ)。',
  fontHintNo:r => 'FONT.BIN を使うには' + T.ja.fileName[r] + 'を入れてください。このままでは実行する機械に' + T.ja.romName[r] + 'が必要です。',
  fontHintFile:r => '実行する機械に' + T.ja.romName[r] + 'がなくても動きます。', fontHintRom:r => '実行する機械に' + T.ja.romName[r] + 'が必要です(ないと文字化け)。',
  needDisks:'ゲームディスク1〜8がすべて必要です(ディスクラベル IPROJ01〜IPROJ08 で自動認識)。',
  needFont:(r, w) => (w === 'cart' ? 'カートリッジROM' : 'フロッピー版') + 'を作るには' + T.ja.fileName[r] + 'を入れてください。できたものは' + T.ja.romName[r] + 'のない機械でも動きます。',
  noDos:'DOS のシステムファイルがありません。作れますが、イメージだけでは起動しません。', en6:'英語6枚版には対応していません。MSX Translations の8枚版を入れてください。',
  other:r => '入れたディスクは' + T.ja.relName[r] + 'です。', otherGo:l => T.ja.tabs[['ko','en','ja'].indexOf(l)] + 'タブで見る',
  relNote:{ en8:'英語版(翻訳:MSX Translations)です。ゲームディスク8枚だけで作れます(ユーザーディスクは任意、日本語版の「データディスク」も使えます)。漢字ROM・フォントファイルは不要で、フロッピー版はありません。',
    ja:'日本語版です。文字は機械に普通に入っている漢字ROMをそのまま使います。漢字ROMファイル(262144バイト)は任意で、入れると結果の中にフォントが入り、漢字ROMのない環境でも動きます。フロッピー版はありません(元のディスクのままで動きます)。' },
  slotHead:['NO','LV','場所'], slotEmpty:'未登録', slotD1:'ディスク1のセーブ(ゲームの一覧と同じ)', slotU:(n, k, m) => m > 1 ? 'ユーザーディスク' + k + '(セーブ一覧' + k + 'ページ、スロット' + (8 * k - 7) + '〜' + 8 * k + '):' + n : 'ユーザーディスクのセーブ:' + n,
  users:n => n + '枚(ページ1〜' + n + ')',
  busy:'作成中...', err:'エラー:', doneFdd:'完了:変更したディスク1(D1.dsk)だけ、または8枚を ZIP でダウンロードできます。ディスク2〜8とユーザーディスクは元のままで使えます。韓国語漢字ROMは不要です。',
  doneCart:(r, f) => '完了:カートリッジROM(Yamanooto、ASCII16-X、各4MB)をダウンロードできます。お持ちのカートリッジに合うものを選んでください。' + (r === 'en8' ? '' : f ? '実行する機械に' + T.ja.romName[r] + 'は不要です。' : '文字は実行する機械の' + T.ja.romName[r] + 'で表示します。'),
  doneDsk:(r, f) => '完了:ハードディスクイメージ(.hd.dsk)と ZIP をダウンロードできます。' + (r === 'en8' ? '' : f ? '実行する機械に' + T.ja.romName[r] + 'は不要です(FONT.BIN)。' : 'この設定では' + T.ja.romName[r] + 'のある機械でのみ文字が表示されます。'),
  files:(n, u, t, mb) => 'ファイル ' + n + ' 個、使用クラスタ ' + u + '/' + t + '(空き ' + mb + 'MB)', zip:'このブラウザは zip の展開に対応していません。展開してから入れてください(最新の Chrome/Edge/Firefox/Safari は対応)。' }
};
const t = () => T[lang];
const rel = () => cls && cls.disks[1] ? cls.release : REL_OF[lang];      // the release the hints talk about: the disks', or the tab's before any are added
const fontRel = () => rel() === 'ja' ? 'ja' : 'ko';

function setLang(l, keep){
  lang = l; document.documentElement.lang = l;
  if (!keep) try { localStorage.setItem('icityLang', l); } catch (e) { }
  document.querySelectorAll('.langs button').forEach(b => { b.setAttribute('aria-selected', b.dataset.lang === l ? 'true' : 'false'); });
  document.querySelectorAll('[data-lang]:not(.langs button)').forEach(e => { if (!e.closest('.langs')) e.hidden = e.dataset.lang !== l; });
  document.querySelectorAll('[data-i]').forEach(e => { const v = T[l][e.dataset.i]; if (typeof v === 'string') e.textContent = v; });
  document.title = T[l].title; $('drop').setAttribute('aria-label', T[l].s1);
  refresh();
}

async function inflate(raw){
  if (typeof DecompressionStream === 'undefined') throw new Error(t().zip);
  const s = new Blob([raw]).stream().pipeThrough(new DecompressionStream('deflate-raw'));
  return new Uint8Array(await new Response(s).arrayBuffer());
}
function segs(){
  document.querySelectorAll('.seg').forEach(seg => {
    seg.querySelectorAll('button').forEach(b => b.addEventListener('click', () => {
      if (b.disabled) return;
      opts[seg.dataset.opt] = b.dataset.v;
      seg.querySelectorAll('button').forEach(x => x.setAttribute('aria-pressed', x === b ? 'true' : 'false'));
      if (seg.dataset.opt === 'pad8') return;      // both sizes are built; the choice only picks the download
      invalidate(); if (seg.dataset.opt === 'target') { applyTarget(); refresh(); } else runHint();
    }));
  });
}
function setSeg(name, v){ document.querySelectorAll('.seg[data-opt="'+name+'"] button').forEach(b => b.setAttribute('aria-pressed', b.dataset.v === v ? 'true' : 'false')); opts[name] = v; }
function invalidate(){ result = null; roms = null; fdd = null; ['dlDsk','dlZip','dlYAMA','dlA16X','dlD1','dlFddZip'].forEach(id => $(id).disabled = true); }
function runHint(){
  const L = t(), r = rel(), fr = fontRel(), tg = opts.target, font = cls && cls.font;
  const run = tg === 'cart' ? L.runCart(r === 'en8' ? r : fr, !!font) : tg === 'fdd' ? L.runFdd : r === 'en8' ? L.runRom('en8') : opts.font === 'file' ? L.runFile(fr) : L.runRom(fr);
  const make = tg === 'dsk' ? L.makeDsk(r === 'en8' ? r : fr, font) : tg === 'cart' && r === 'ja' ? L.makeCartJa : L.makeNeed(r === 'en8' ? r : fr);
  $('runHint').textContent = run + ' · ' + make;
  $('fontFile').textContent = L.fontFile(fr); $('fontRom').textContent = L.fontRom(fr);
  $('fontHint').textContent = !font ? L.fontHintNo(fr) : opts.font === 'file' ? L.fontHintFile(fr) : L.fontHintRom(fr);
}
function applyTarget(){
  document.querySelectorAll('.need tr[data-t]').forEach(r => r.classList.toggle('cur', r.dataset.t === opts.target));
  const cart = opts.target === 'cart', fl = opts.target === 'fdd', dsk = !cart && !fl;
  document.querySelectorAll('.dsk-only').forEach(r => { if (r.id === 'dosRow') r.hidden = !dsk || !(cls && cls.dos['MSXDOS2.SYS'] && cls.dos['NEXTOR.SYS']); else r.hidden = !dsk; });
  $('fontRow').hidden = !dsk || rel() === 'en8';
  $('savesRow').hidden = fl; $('padRow').hidden = !cart;
  $('dlDsk').hidden = !dsk; $('dlZip').hidden = !dsk; $('dlYAMA').hidden = !cart; $('dlA16X').hidden = !cart; $('dlD1').hidden = !fl; $('dlFddZip').hidden = !fl;
  $('targetHint').textContent = t().tHint[opts.target];
  const fddBtn = document.querySelector('.seg[data-opt="target"] button[data-v="fdd"]'); fddBtn.disabled = rel() !== 'ko';
  relNote();
  runHint();
}
function relNote(){
  const n = $('relnote'), L = t(), r = cls && cls.disks[1] ? cls.release : null;
  n.textContent = ''; n.hidden = true;
  if (!r) return;
  const own = LANG_OF[r];
  if (own && own !== lang) {
    n.append(L.other(r));
    const b = document.createElement('button'); b.className = 'link'; b.textContent = L.otherGo(own); b.addEventListener('click', () => setLang(own)); n.append(b);
    if (L.relNote[r]) n.append(document.createElement('br'), L.relNote[r]);
    n.hidden = false;
  } else if (r === 'en6') { n.textContent = L.en6; n.hidden = false; }
  else if (L.relNote[r] && r !== REL_OF[lang]) { n.textContent = L.relNote[r]; n.hidden = false; }
}

async function ingest(files){
  for (const f of files) items.push({ name: f.name, data: new Uint8Array(await f.arrayBuffer()) });
  await refresh();
}
async function refresh(){
  invalidate(); show('', '');
  try { cls = await ICITY.classify(items, inflate); } catch (e) { cls = null; show('bad', e.message); return; }
  const L = t(), c = $('checks'); c.innerHTML = '';
  const chip = (a, v, k) => { const d = document.createElement('div'); d.className = 'chip ' + k; d.innerHTML = '<span></span><span></span>'; d.children[0].textContent = a; d.children[1].textContent = v; c.appendChild(d); };
  for (let n = 1; n <= 8; n++) chip(L.disk(n), cls.disks[n] ? '✓' : L.none, cls.disks[n] ? 'ok' : 'bad');
  chip(L.user, !cls.user ? L.userNone : cls.users.length > 1 ? '✓ ' + L.users(cls.users.length) : '✓ ' + cls.user.name, cls.user ? 'ok' : 'opt');
  const r = cls.disks[1] ? cls.release : null, en8 = rel() === 'en8', fr = fontRel();
  if (r) chip(L.rel, L.relName[r], r === 'en6' ? 'bad' : 'ok');
  if (rel() !== 'ko' && opts.target === 'fdd') setSeg('target', 'dsk');
  const needFont = !en8 && fr === 'ko' && opts.target !== 'dsk';      // the Korean release needs Kittya's font for the cartridge and the floppy
  if (!en8) chip(L.font, cls.font ? '✓ ' + cls.font.name : needFont ? L.req : L.opt, cls.font ? 'ok' : needFont ? 'bad' : 'opt');
  const hasA = !!cls.dos['MSXDOS2.SYS'], hasN = !!cls.dos['NEXTOR.SYS'], hasC = !!cls.dos['COMMAND2.COM'];
  if (opts.target === 'dsk') {
    chip('MSXDOS2.SYS', hasA ? '✓' : L.none, hasA ? 'ok' : 'opt');
    chip('NEXTOR.SYS', hasN ? '✓' : L.none, hasN ? 'ok' : 'opt');
    chip('COMMAND2.COM', hasC ? '✓' : L.none, hasC ? 'ok' : 'opt');
  }
  slotList();
  const notes = $('notes'); if (cls.notes.length) { notes.hidden = false; notes.textContent = cls.notes.join('\n'); } else notes.hidden = true;
  $('fontFile').disabled = !cls.font || en8;
  if (!cls.font || en8) setSeg('font', 'rom');
  else if (opts.font === 'rom' && !$('fontFile').dataset.userRom) setSeg('font', 'file');
  $('dosRow').hidden = !(hasA && hasN);
  if (hasA && !hasN) opts.dos = 'ascii'; else if (hasN && !hasA) opts.dos = 'nextor';
  applyTarget();
  const ok = [1,2,3,4,5,6,7,8].every(n => cls.disks[n]);
  const cart = opts.target === 'cart', fl = opts.target === 'fdd';
  $('make').disabled = !ok || r === 'en6' || (needFont && !cls.font);
  if (r === 'en6') show('bad', L.en6);
  else if (!ok) { if (items.length) show('bad', L.needDisks); }
  else if (needFont && !cls.font) show('bad', L.needFont(fr, opts.target));
  else if (!cart && !fl && !hasA && !hasN) show('warn', L.noDos);
}
function slotList(){
  const L = t(), box = $('slots'); box.innerHTML = '';
  if (!cls || !cls.disks[1]) { box.hidden = true; return; }
  const one = (title, disk, off) => {
    let rows;
    try { rows = ICITY.saveSlots(cls.disks[1].data, disk); } catch (e) { return; }
    const d = document.createElement('div'), h = document.createElement('h3'), tb = document.createElement('table');
    h.textContent = title; d.appendChild(h);
    const hr = document.createElement('tr'); L.slotHead.forEach((v, i) => { const th = document.createElement('th'); th.textContent = v; if (i < 2) th.className = 'num'; hr.appendChild(th); }); tb.appendChild(hr);
    for (const x of rows) {
      const tr = document.createElement('tr');
      [[x.n + (off || 0), 'num'], [x.valid ? x.lv : '--', 'num'], [x.valid ? x.place : L.slotEmpty, x.valid ? '' : 'e']].forEach(([v, k]) => { const td = document.createElement('td'); td.textContent = v; if (k) td.className = k; tr.appendChild(td); });
      tb.appendChild(tr);
    }
    d.appendChild(tb); box.appendChild(d);
  };
  one(L.slotD1, cls.disks[1].data);
  cls.users.forEach((u, k) => one(L.slotU(u.name, k + 1, cls.users.length), u.data, 8 * k));      // numbered as in the game's list
  box.hidden = !box.children.length;
}
function show(kind, text){ const m = $('msg'); m.className = kind === 'bad' ? 'bad' : kind === 'ok' ? 'ok' : ''; m.style.color = kind === 'warn' ? 'var(--warn)' : ''; m.textContent = text; }

async function make(){
  $('make').disabled = true; invalidate(); const log = $('log'); log.hidden = false; log.textContent = '';
  const Lg = m => { log.textContent += m + '\n'; log.scrollTop = log.scrollHeight; };
  const L = t(), r = cls.release, fr = fontRel();
  show('', L.busy);
  await new Promise(res => setTimeout(res, 30));
  try {
    if (opts.target === 'fdd') {
      fdd = ICITY.buildFdd({ assets: A, cls, log: Lg });
      $('dlD1').disabled = false; $('dlFddZip').disabled = false;
      show('ok', L.doneFdd);
      $('make').disabled = false; return;
    }
    if (opts.target === 'cart') {
      roms = ICITY.buildCart({ assets: A, cls, keepSaves: opts.saves === 'keep', pad8: true, log: Lg });
      $('dlYAMA').disabled = false; $('dlA16X').disabled = false;
      show('ok', L.doneCart(r === 'en8' ? r : fr, !!cls.font));
      $('make').disabled = false; return;
    }
    const use = Object.assign({}, cls, { dos: {} });
    const want = opts.dos === 'nextor' ? ['NEXTOR.SYS','COMMAND2.COM'] : ['MSXDOS2.SYS','COMMAND2.COM'];
    for (const n of want) if (cls.dos[n]) use.dos[n] = cls.dos[n];
    const b = ICITY.build({ assets: A, cls: use, autoexec: opts.autoexec === 'on', autoexecText: 'ICITY', readme: opts.readme === 'on',
      useFont: opts.font === 'file', keepSaves: opts.saves === 'keep', log: Lg });
    const label = ($('label').value || 'ICITYDOS2').replace(/[^A-Za-z0-9_ ]/g, '').slice(0, 11) || 'ICITYDOS2';
    const img = ICITY.makeImage(b.rootFiles, b.boot, label, new Date());
    const files = ICITY.flatten(b.rootFiles, '');
    result = { image: img.image, files, fontOn: b.fontOn, n: files.length, used: img.used, total: img.clusters, cb: img.clusterBytes };
    Lg(L.files(files.length, img.used, img.clusters, Math.round((img.clusters - img.used) * img.clusterBytes / 1048576 * 10) / 10));
    $('dlDsk').disabled = false; $('dlZip').disabled = false;
    show('ok', L.doneDsk(r === 'en8' ? r : fr, b.fontOn));
  } catch (e) { show('bad', L.err + e.message); Lg(L.err + e.message); }
  $('make').disabled = false;
}
function save(name, bytes, type){
  const a = document.createElement('a'); a.href = URL.createObjectURL(new Blob([bytes], { type: type || 'application/octet-stream' })); a.download = name;
  document.body.appendChild(a); a.click(); setTimeout(() => { URL.revokeObjectURL(a.href); a.remove(); }, 4000);
}
segs();
document.querySelectorAll('.langs button').forEach(b => b.addEventListener('click', () => setLang(b.dataset.lang)));
let start = 'ko'; try { const s = localStorage.getItem('icityLang'); if (T[s]) start = s; } catch (e) { }
setLang(start, true);
const drop = $('drop'), pick = $('pick');
drop.addEventListener('click', () => pick.click());
drop.addEventListener('keydown', e => { if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); pick.click(); } });
pick.addEventListener('change', () => { ingest(Array.from(pick.files)); pick.value = ''; });
['dragenter','dragover'].forEach(ty => drop.addEventListener(ty, e => { e.preventDefault(); drop.classList.add('over'); }));
['dragleave','drop'].forEach(ty => drop.addEventListener(ty, e => { e.preventDefault(); drop.classList.remove('over'); }));
drop.addEventListener('drop', e => ingest(Array.from(e.dataTransfer.files)));
$('fontRom').addEventListener('click', () => { $('fontFile').dataset.userRom = '1'; });
$('fontFile').addEventListener('click', () => { delete $('fontFile').dataset.userRom; });
$('make').addEventListener('click', make);
const base = () => ({ en8:'ICITY_EN', ja:'ICITY_JA' })[cls && cls.release] || 'ICITY';
$('dlDsk').addEventListener('click', () => result && save(base() + (opts.autoexec === 'on' ? '_AUTO' : '') + '.hd.dsk', result.image));
$('dlZip').addEventListener('click', () => result && save(base() + '_SD.zip', ICITY.zipWrite(result.files), 'application/zip'));
$('dlD1').addEventListener('click', () => fdd && save('D1.dsk', fdd[0].data));
$('dlFddZip').addEventListener('click', () => fdd && save('ICITY_FDD.zip', ICITY.zipWrite(fdd.map(d => ({ path: 'I-City(k)(' + d.n + '-8).dsk', data: d.data }))), 'application/zip'));
['YAMA','A16X'].forEach(ty => $('dl' + ty).addEventListener('click', () => { const tag = ty === 'A16X' && opts.pad8 === 'on' ? 'A16X_8MB' : ty, x = roms && roms.find(y => y.tag === tag); if (x) save(base() + '_' + tag + '.rom', x.rom); }));
})();
</script>
</body>
</html>
