# 인수인계 — 2026-10-04 정리 (이전 2026-10-01 판을 갱신)

새 세션은 이 문서부터 읽는다. 저장소 GitHub `muhanpong/Illusion_City_MSXDOS2`(공개 전환 예정; 옛 이름 Illucity_HD), 로컬 `/home/sysop/data/Illucity_HD`,
작업 브랜치 **`illuk_CART` = 명령줄 도구의 단일 기준 브랜치**(git fetch 먼저). 2026-10-03 히스토리를 다시 써서 그 이전 커밋 해시는 원격에 없다(트리로 비교).
세부: `HANDOFF_FDD.md`(게임 구조), `fdd/README.md`(플로피판), `cart/HANDOFF_CART.md`(카트), `PLAN_BINPATCH.md`(DOS2), `PLAN_EN8.md`·`HANDOFF_EN8.md`·`HANDOFF_EN9.md`(영문판),
`phase0/songscan/SONGSCAN.md`(곡 사용처), `webapp/README.md`(웹 도구, 판별 지원·시험).

## 0. 사용자 규칙
- 답은 한국어로 짧게. 커밋·푸시는 사용자가 요청할 때만(다른 세션이 "사용자 승인"을 전해도 이 세션에서 확인). 커밋 이메일은 **`muhanpong@users.noreply.github.com`만**(naver 주소 금지, git config에 설정됨).
- 웹 도구 `hdtool/webapp/`는 네 브랜치(master, nextor_emu, msxdos2, illuk_CART)에 같은 내용. 최종본은 illucity-hd-cart 세션이 관리. 고치면 네 곳 모두 커밋·푸시:
  다른 브랜치에는 `git worktree`로 해당 파일만 `git checkout <커밋> -- <경로>`. **폴더째 넣지 말 것**(msxdos2의 `cart/HANDOFF_CART.md`는 예전 판이 따로 있음).
  master 루트 `README.md`(한·영·일 소개)는 master에만 있다.
- MiSTer 담당 세션 **illucity-hd-2f**(`bridge:session_019jGMSwVTXyyKi51waQFXcC`): 푸시 전 fetch, 푸시 후 해시 알림. 실기·MiSTer 확인과 GitHub Release를 맡는다.
- **헌정:** 한글 번역·한글 글꼴(KANJI.rom)·인코딩을 해 주신 **키티야 님**께 드리는 작업. 관련 언급은 차분하고 예의 있게. 영문판에는 **MSX Translations** 크레딧.
- 원본 디스크는 저장소 밖: `illucity_K.zip`(8장), `userdisk.DSK`, `KANJI.rom`; 영문·일본어판 `~/illusion_city/x/`(en_msx_translations, en_translation=6장판 미지원, ja: 게임 1–8 + Data Disk 1–4).
  일본 GT 한자 ROM `~/.openMSX/share/machines/panasonic/fs-a1gt_kanjifont.rom`. `I-CITY_K.DSK`는 글꼴 포트 59h/5Bh 판이라 비교에 쓰지 말 것.

## 1. 지금 지원하는 것 (2026-10-04, 모두 푸시됨: illuk_CART b3e26db, master 1e05b5b, nextor_emu 4e5d0be, msxdos2 d0d4fda)
| 판 | DOS2(HDD/SD) | 카트(A16X·YAMA 4MB, A16X 8MB 선택) | 플로피 | 글꼴 |
|---|---|---|---|---|
| 한글판 | ○ | ○ | ○(디스크 1만 패치) | KANJI.rom: 카트·플로피 필수, DOS2 선택 |
| 영문 8장판 | ○(96슬롯) | ○ | × | 없음(한자 ROM 안 읽음) |
| 일본어판 | ○ | ○ | × | 선택(없으면 기계의 한자 ROM, G1/G2 없음) |
- 판 식별은 웹(`core.js`)과 Python이 같다: 영문 = 부트 섹터 +53h, 6장판 = 거부, 일본어 = 디스크 1 파일 10의 가나 수, 나머지 한글.
- **유저 디스크 최대 12장**: k장째의 8슬롯 → 유저 디스크 세이브 목록 k페이지(DOS2 `DU_0578.DAT` (k−1)×8KB, 카트 플래시). 웹은 파일 이름 순, CLI는 `--user DISK`(반복).
- **8MB 옵션**: MiSTer OSD에서 매퍼를 ASCII16X로 직접 고를 때(코어가 4MB 초과만 플래시로 받음). 웹 선택지, `mkcart.py --pad8`.
- 웹 도구는 언어 탭(한국어·영어·일본어, 탭 이름은 보이는 언어로).
- 시험: `webapp/test_cli.sh`(같은 브랜치 Python 결과 = core.js 바이트 비교: 영문, 일본어 글꼴 없음/있음, 유저 디스크 5장), 한글판 `test_node.js`·`test_cart.js`·`test_fdd.js`.
  한글판 md5: A16X 45d25f08…, YAMA b94f9191…, A16X 8MB 43186fe9…(유저 디스크 1장일 때 지금까지 불변).

## 2. 정리한 것 (2026-10-04)
- `illuk_EN` 브랜치를 illuk_CART에 병합(e503993) 후 정리, 영문 worktree `/home/sysop/data/Illucity_HD-en` 제거. 영문판 작업도 illuk_CART에서 한다(`HANDOFF_EN9.md`).
- 이전 세션(2026-10-01)의 미커밋분과 ARMI 제거(카트 ROM), G2 등은 모두 반영됨.

## 3. 다음 할 일 (사용자 결정 대기)
1. **PC 세이브 변환기(웹 도구)** — 미착수. 카트 ROM/MiSTer `.sav` → 슬롯 목록·DOS2 DAT, 반대로 새 ROM 세이브 영역에 넣기.
   MiSTer `.sav`: 512바이트 헤더(`MFX16XDB`, mode 02, 0x10–0x1F 128비트 비트맵, 비트 = ROM 64KB 블록) + 세워진 블록을 오름차순 64KB씩(코어 `rtl/flash_dirtysave.sv`).
2. **카트 게임 안 플로피 백업** — 방식 미정(GT 내장 DSKIO 호출 실패, FDC 직접 제어만 남음). 안전용이면 1번이 낫다는 것이 지금까지의 제안.
3. 확인 못 한 것: 엔딩 전체 실제 진행, 플로피판 디스크 3–6·8, 실기(플로피판·영문판·일본어판·유저 디스크 여러 장), 영문판 장소 이름 해독(사전 압축 텍스트).
4. 플로피판 글자 여유(한글 1,109자 사용): 디스크 1 남은 2섹터 ≈ 80자, ARMI 회수 시 MIDI 모드 RAM 한계 ≈ 300자.

## 4. 이번 세션에서 확인한 사실 (요약)
- **커널 모드 표 E908h**: 0=파일 4, 1=파일 5(타이틀·오프닝), 2=**파일 14(엔딩 인트로, 8000h)**, 3=파일 4. `(0081)=모드, (0082)=0, SP=FAF8h, PC=E000h`로
  강제 진입 가능(시험에 사용). 파일 14의 ADFEh는 실제로 불린다(illucity-hd-2f가 실기에서 확인; 내가 처음 "죽은 코드"라 한 것은 틀림).
- **글자 인코딩**: 게임 글자는 Shift-JIS 코드, 키티야 님 KANJI.rom은 JIS 16–40행을 KS X 1001 순서로 → EUC-KR로 바로 유니코드. 41행 이후는 번역용 추가 글자.
- **세이브 슬롯(1KB)**: +3F8h 'ILCITY', +16h 장면 코드 3글자, +277h 레벨. 장소 이름은 디스크 1 파일 10의 지역 표(8026h, 30항목, 3글자→2글자 매칭).
  유저 디스크 세이브: 해저도시, 샤팅지구, 생체연구소부지, 환영성내부, 주라구, 티우챤지구, 사이쿤지구, 토로지구(전에 잘못 읽은 이름은 문서에서 고침).
- **곡 번호**: CA48h(1-based)를 파일 7 5050h만 쓴다. 출처는 INF 장면 기록 +24/+25, 이벤트 스크립트 'B', 바이트코드 `c8 0f c1 n`, 디스크 1 프로그램 상수.
- **MIDI 곡 캐시**: 인덱스 0250h–03C9h(MIDI 섹터 캐시 시작은 3CAh). 섹터 캐시 끝이 시작보다 작으면 file 13이 크기를 5A0h로 잡아 덮어씀(플로피판에서 3C8h로 했다가 겪음).
- **부팅 시간(에뮬 시간)**: 본체 12.5초, 플로피판 글꼴 적재 +1.4초, MIDI 곡 미리 읽기 약 85초(원본과 같음)가 가장 김.
- **RAM 지도(실행 중)**: 00 페이지3 시스템, 01 파일 10·INF, 02–03 파일 7, 04 파일 0–3, 05 파일 8, 06 파일 9, 07 이벤트 스크립트, 08–0F 현재 디스크 장면 데이터
  (0C는 두 지점에서 비어 있음), 10 파일 13, 11 MIDI 작업(FM은 빔), 12–1D 곡 캐시(FM은 13–19 빔), 1E 곡 끝+섹터 캐시+글꼴 뒤, 1F 글꼴.
- 디스크 1 섹터 지도(플로피판)는 대화에서만 정리됨 — 필요하면 `fdd/README.md`에 옮길 것.

## 5. 시험 도구 (`fdd/test/`)
- `run.tcl`: 원본 플로피 게임을 메뉴 자동 조작으로 진행(디스크 교체 자동). 변수: SOUND 0 FM/1 MIDI, MAIN 1 세이브 지점/2 오프닝/3 스타트,
  MED 4 유저 디스크, SLOT 0–7. **번호를 틀리면 헛도니 화면 캡처로 확인할 것**(이번 세션에 여러 번 헛돎).
- `fv.tcl`(글자 대조), `segdump2.tcl` + `segan.py`(RAM 지도), `mode2.tcl`/`cartm2.tcl`/`dos2m2.tcl`(엔딩 인트로 강제 진입), `bt.tcl`(부팅 시간), `gl.tcl`(글리프 수집).
- openMSX: 표준 GT `Panasonic_FS-A1GT`(한글 롬 없음), 한글 롬 기계 `kittya`. 헤드리스는 `SDL_VIDEODRIVER=offscreen` + `set renderer SDLGL-PP`
  (`set renderer none`이면 일부 진행이 멈춘 적 있음). openMSX는 플로피 이미지에 세이브를 써 넣으므로 원본은 복사해서 쓸 것.
