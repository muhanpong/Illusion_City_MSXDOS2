# 인수인계 — 2026-10-01 세션 정리와 다음 할 일

새 세션은 이 문서부터 읽는다. 저장소 `/home/sysop/data/Illucity_HD`, 작업 브랜치 `illuk_CART`(git fetch 먼저).
세부는 각 문서: `HANDOFF_FDD.md`(게임 구조), `fdd/README.md`(플로피판), `cart/HANDOFF_CART.md`(카트), `PLAN_BINPATCH.md`(DOS2),
`phase0/songscan/SONGSCAN.md`(곡 사용처), `webapp/README.md`(웹 도구).

## 0. 사용자 규칙
- 답은 한국어로 짧게. 커밋·푸시는 요청할 때만. 저자 muhanpong@naver.com(저장소 git config).
- 웹 도구 `hdtool/webapp/`는 네 브랜치(master, nextor_emu, msxdos2, illuk_CART)에 같은 내용. 고치면 네 곳 모두 커밋·푸시.
  다른 브랜치에는 `git worktree`로 해당 파일만 `git checkout <커밋> -- <경로>` 해서 넣는다. **폴더째 넣지 말 것**
  (msxdos2의 `cart/HANDOFF_CART.md`는 예전 판이 따로 있다: 53dc383에서 덮어썼다가 f17b69b로 되돌린 적 있음).
- 다른 컴퓨터의 Claude 세션 **illucity-hd-2f**(MiSTer 담당)가 같은 저장소를 쓴다. 푸시 전 fetch, 푸시 후 해시를 SendMessage로 알림
  (`to: bridge:session_019jGMSwVTXyyKi51waQFXcC`). 그 세션이 실기·MiSTer 확인을 해 준다.
- **헌정:** 이 작업은 한글 번역·한글 글꼴(KANJI.rom)·인코딩을 해 주신 **키티야 님**께 드리는 것. 관련 언급은 차분하고 예의 있게
  (웹 도구 첫 화면, DOS2 README, `fdd/README.md`에 있음; 한글화 글 https://blog.naver.com/kkitty5425/222619726741).
- 원본 디스크는 저장소 밖: `illucity_K.zip`(8장), `userdisk.DSK`, `KANJI.rom`. `I-CITY_K.DSK`는 글꼴 포트가 59h/5Bh로 바뀐 판이라 비교에 쓰지 말 것.

## 1. 이번 세션에 끝낸 것 (모두 푸시됨, 아래 2절의 미커밋분 제외)
| 내용 | 위치 |
|---|---|
| 카트 A16X 파일에 `"ASCII16X"` 서명(0010h), 4MB 그대로 플래시 매퍼 인식 | `cart/cart.asm`, `mkcart.py` |
| 세이브 목록 페이지 넘김을 게임패드로도(카트: 조이스틱 1·2, DOS2: 조이스틱 1) | `cart.asm`, `mkdos2/icity.asm` |
| **플로피판(한글 롬 불필요)**: 디스크 1만 패치, 글꼴 1395자를 550h–575h에, 세그먼트 1Fh·1Eh(2000h~)에 적재 | `fdd/` (`mkfdd.py`, `fdd.asm`) |
| 곡 사용처 정적 스캐너(INF·이벤트 스크립트·바이트코드) | `phase0/songscan/` |
| 게임이 찍는 글리프 전체 정적 스캐너(1395자, 실행 기록과 대조) | `phase0/glyphscan/` |
| 웹 도구: 플로피 모드, 첫 화면 실행 조건 표, 키티야 님 헌정, `.hd.dsk` 이름, 세이브 슬롯 목록(NO/LV/장소) | `webapp/` |
| **G2**: 엔딩 인트로(디스크 1 파일 14, 커널 모드 2)의 한자 ROM 읽기 사본(ADFEh)을 DOS2·카트에서도 글꼴로 | `mkdos2/patches.py`, `cart/mkcart.py` |
| 도구 버전 2026-10-01 표시(이전 DOS2·카트 결과물은 엔딩 인트로 글자가 깨짐 — 사용자가 공유 게시물에 안내함) | 웹 도구 아래, DOS2 README |

## 2. 마지막으로 넣은 것 (illuk_CART 56e978b, 웹 도구는 master d16cd5a / nextor_emu eee6336 / msxdos2 a452d21)
- **카트 ROM에서 ARMI.COM·ARMI.DOC(디스크 1 섹터 588h–597h, 덤 RCP 플레이어) 제거**: 디스크의 빈 섹터 값(598h)으로 채움.
  `mkcart.py blank_armi`, `webapp/core.js` buildCart. 새 md5: A16X 45d25f081eb37618dd723a0381e393cc, YAMA b94f9191362eee7ef14ca21c2dded591.
  시험: 웹 결과 = mkcart(바이트 일치), 옛 ROM 세이브를 새 ROM이 읽음(두 매퍼 16/16), 파일 14 경로 386/386, 섹터 읽기 125회 중 불일치 2는 G1·P 패치 자리(정상).
  플로피·DOS2에는 ARMI가 그대로 있다(플로피는 원본 구성, 회수 0순위로만 표시).
- `fdd/test/`(이번 세션의 시험 스크립트), 이 문서. 웹 도구(`core.js`, `icity_dsk_maker.html`)가 바뀌었으므로 네 브랜치 모두에 넣는다.

## 3. 다음 할 일 (사용자 결정 대기 포함)
1. **PC 세이브 변환기(웹 도구)** — 사용자가 범위를 확인함, 미착수:
   - 4MB 카트 ROM(실기 덤프, openMSX가 쓴 파일)에서 세이브 추출 → 슬롯 목록 + `D1_0578.DAT`/`DU_0578.DAT`(DOS2 형식, 슬롯 n = n×1KB).
   - 추출한 세이브(또는 DAT)를 새 ROM의 세이브 영역(350000h, 24슬롯 묶음 × 8 + 예비, 헤더 'IC'·묶음·세대)에 넣어 내보내기.
   - MiSTer `.sav` 형식은 모름 → illucity-hd-2f에 물어볼 것(197,120바이트 파일을 분석한 적 있음).
2. **카트 게임 안 플로피 백업** — 사용자가 "카트리지만"이라고 함, 방식 미정:
   - 시험 결과: GT 내장 디스크 ROM(슬롯 3-2)의 DSKIO는 카트 INIT 시점에 초기화 없이 부르면 끝나지 않음, 디스크 ROM INIT을 부르면 돌아오지 않음(부팅까지 하는 것으로 보임).
     시험 ROM은 scratchpad에만 있었음(`probe/dp.asm`: CALSLT로 INIT, ENASLT 8Bh 후 DSKIO 4010h).
   - 남은 길: 카트에 GT 내장 FDC 직접 제어 드라이버. GT·ST 전용, 포맷된 디스크 필요, 유저 디스크 한 장에 8슬롯, 카트 남는 자리 빠듯(YAMA).
   - 안전용 백업이면 1번(PC 변환기)이 낫다는 것이 지금까지의 제안.
3. 확인 못 한 것: 엔딩 전체를 실제 진행으로(지금은 모드 2 강제 진입만), 플로피판 디스크 3–6·8 구간, 실기(플로피판·G2판),
   blueMSX(`/ide1primary` 등 명령행은 문서로만 확인), 일본어 원본 디스크 지원(패치 주소 비교 필요, 이미지 없음).
4. 플로피판 글자 여유(한글 2,350자 중 1,109자 사용): 지금 디스크 1 남은 2섹터 ≈ 80자, ARMI 회수 시 디스크는 풀리지만 MIDI 모드 RAM이 한계(≈300자), FM만이면 전부 가능.

5. **영문 8장판(MSX Translations) DOS2·카트**: 브랜치 `illuk_EN`(worktree `/home/sysop/data/Illucity_HD-en`, 세션 illucity-hd-en8)에서 진행. 계획·인수인계는 그 브랜치의 `hdtool/PLAN_EN8.md`, `HANDOFF_EN8.md`.

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
