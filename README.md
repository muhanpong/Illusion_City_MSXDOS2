# Illusion City MSXDOS2

MSX2+/turbo R game **Illusion City**(幻影都市, 1991, Micro Cabin)를 하드디스크(MSX-DOS2)·카트리지 ROM·플로피로 옮기는 변환 도구와 그 결과물입니다. 원본 게임 데이터나 번역 데이터는 이 저장소에 들어 있지 않습니다 — 직접 가진 디스크 이미지를 웹 도구에 넣어 결과물을 만듭니다.

This repository holds the tools (and build output) that repackage the MSX2+/turbo R game **Illusion City** (幻影都市, 1991, Micro Cabin) as an MSX-DOS2 hard-disk/SD version, a standalone cartridge ROM, or a floppy set. No original game or translation data is stored here — you feed your own disk images to the web tool.

このリポジトリは、MSX2+/turbo R 用ゲーム **幻影都市（Illusion City）**（1991年、マイクロキャビン）をハードディスク（MSX-DOS2）版・カートリッジROM版・フロッピー版に変換するツールとその成果物です。オリジナルのゲームデータや翻訳データはここには含まれません — お手持ちのディスクイメージを Web ツールに読み込んで作ります。

---

## 한국어

### 무엇을 만들 수 있나
- **MSX-DOS2 하드디스크/SD판**: `ICITY.COM` 런처 + 디스크를 섹터 단위로 쪼갠 파일들. MSX-DOS2(ASCII 2.x)나 Nextor 위에서 돌아갑니다. 디스크마다 96개 세이브 슬롯(페이지 전환).
- **카트리지 ROM판**: Yamanooto / ASCII16-X 매퍼, 4MB. 꽂기만 하면 부팅하고, 세이브는 카트리지 플래시에 기록됩니다.
- **플로피판**(한국어판 전용): 한글 한자 ROM이 없는 기계에서도 원본 디스크 8장 그대로 돌아가도록 디스크 1만 패치합니다.

### 지원 판본
- **한국어판**: 키티야 님의 한글 번역·한글 글꼴(KANJI.rom)·인코딩 작업을 바탕으로 합니다. 화면에 나오는 한글은 모두 키티야 님의 작업입니다. ([한글화 글](https://blog.naver.com/kkitty5425/222619726741))
- **영문판**: MSX Translations의 8장판 영어 번역을 바탕으로 합니다.
- **일본어 원본판**: 번역 없이 원본 그대로, 기계 내장 한자 ROM을 씁니다.

### 만드는 법
`hdtool/webapp/icity_dsk_maker.html`을 브라우저로 열어 디스크 이미지를 넣으면 됩니다. 모든 처리는 브라우저 안에서만 이뤄지고 파일은 어디로도 전송되지 않습니다. 명령줄 도구(Python)도 `hdtool/mkdos2/`, `hdtool/cart/`, `hdtool/fdd/`에 있습니다.

### 브랜치
| 브랜치 | 내용 |
|---|---|
| `master` | Nextor 디스크 에뮬레이션판(가장 이른 변환 방식) |
| `nextor_emu` | 위와 동일 계열, 웹 도구 포함 |
| `msxdos2` | MSX-DOS2 런처판(`hdtool/mkdos2`) |
| `illuk_CART` | 카트리지판(`hdtool/cart`)과 플로피판(`hdtool/fdd`), 웹 도구 |
| `illuk_EN` | 영문 8장판(MSX Translations) 작업 |

### 실기 확인
Panasonic FS-A1GT(turbo R) + MMC/SD V4 / MegaFlashROM SCC+ SD, MiSTer MSX1 코어에서 확인하며 만들고 있습니다.

---

## English

### What it builds
- **MSX-DOS2 hard-disk/SD release**: an `ICITY.COM` launcher plus the disks split into per-sector chunk files. Runs under MSX-DOS2 (ASCII 2.x) or Nextor. 96 paged save slots per disk.
- **Cartridge ROM release**: Yamanooto / ASCII16-X mapper, 4MB. Boots on its own when plugged in; saves are written to the cartridge's own flash.
- **Floppy release** (Korean release only): patches disk 1 only, so the original 8 floppies run without a Korean Kanji ROM.

### Supported releases
- **Korean**: built on Kittya's Korean translation, Korean font (KANJI.rom) and encoding work. Every piece of Korean text on screen is their work. ([Kittya's write-up, Korean](https://blog.naver.com/kkitty5425/222619726741))
- **English**: built on the 8-disc English translation by **MSX Translations**.
- **Japanese original**: unmodified text, reads the machine's own Kanji ROM.

### Building
Open `hdtool/webapp/icity_dsk_maker.html` in a browser and feed it your disk images — everything runs in the browser, nothing is uploaded anywhere. Command-line (Python) tools live in `hdtool/mkdos2/`, `hdtool/cart/`, `hdtool/fdd/`.

### Branches
| Branch | Contents |
|---|---|
| `master` | Nextor disk-emulation build (the earliest approach) |
| `nextor_emu` | Same family, with the web tool |
| `msxdos2` | MSX-DOS2 launcher release (`hdtool/mkdos2`) |
| `illuk_CART` | Cartridge release (`hdtool/cart`), floppy release (`hdtool/fdd`), web tool |
| `illuk_EN` | English 8-disc (MSX Translations) work |

### Tested on
Developed and checked against a Panasonic FS-A1GT (turbo R) with MMC/SD V4 or MegaFlashROM SCC+ SD, and the MiSTer MSX1 core.

---

## 日本語

### 作れるもの
- **MSX-DOS2 ハードディスク/SD版**: `ICITY.COM` ランチャーと、セクタ単位に分割されたディスクのファイル群。MSX-DOS2（ASCII 2.x系）または Nextor 上で動作します。ディスクごとに96個のセーブスロット（ページ切替）。
- **カートリッジROM版**: Yamanooto / ASCII16-X マッパー、4MB。挿すだけで起動し、セーブはカートリッジ内のフラッシュに書き込まれます。
- **フロッピー版**（韓国語版のみ）: ディスク1のみ修正し、韓国語漢字ROMのない機種でも原本の8枚組がそのまま動くようにします。

### 対応リリース
- **韓国語版**: キティヤ氏による韓国語翻訳・韓国語フォント（KANJI.rom）・エンコーディング作業がもとになっています。画面に出る韓国語はすべて氏の作業です。（[キティヤ氏の韓国語化記事](https://blog.naver.com/kkitty5425/222619726741)）
- **英語版**: **MSX Translations** による8枚組英語翻訳がもとになっています。
- **日本語オリジナル版**: テキストは無修正で、機種本体の漢字ROMを読みます。

### 作り方
`hdtool/webapp/icity_dsk_maker.html` をブラウザで開き、お手持ちのディスクイメージを読み込ませてください。処理はすべてブラウザ内で完結し、どこにも送信されません。コマンドライン版（Python）は `hdtool/mkdos2/`、`hdtool/cart/`、`hdtool/fdd/` にあります。

### ブランチ
| ブランチ | 内容 |
|---|---|
| `master` | Nextor ディスクエミュレーション版（最初期の方式） |
| `nextor_emu` | 同系統、Web ツール付き |
| `msxdos2` | MSX-DOS2 ランチャー版（`hdtool/mkdos2`） |
| `illuk_CART` | カートリッジ版（`hdtool/cart`）とフロッピー版（`hdtool/fdd`）、Web ツール |
| `illuk_EN` | 英語8枚組（MSX Translations）版の作業 |

### 動作確認環境
Panasonic FS-A1GT（turbo R）+ MMC/SD V4 または MegaFlashROM SCC+ SD、および MiSTer MSX1 コアで確認しながら開発しています。
