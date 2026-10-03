# 인수인계 — 영문 8장판(MSX Translations) 작업, en8 → en9 (2026-10-04)

먼저 읽을 것: 이 문서 → `hdtool/PLAN_EN8.md` 맨 위 "진행 상태" → `hdtool/HANDOFF_EN8.md` → `hdtool/mkdos2/test/en8/README.md`, `hdtool/cart/test/en8/README.md`.
**2026-10-04 정리:** `illuk_EN`은 `illuk_CART`에 병합(e503993)되고 정리되었다. 영문판 작업도 이제 **`illuk_CART`**(명령줄 도구의 단일 기준 브랜치,
저장소 `muhanpong/Illusion_City_MSXDOS2`, 커밋 이메일 `muhanpong@users.noreply.github.com`만)에서 한다. 아래의 worktree·브랜치·"커밋 안 된 것" 이야기는
정리 전 기록이다(웹 파일은 illuk_CART가 최종본이라 버렸다). 다른 세션과 같은 폴더를 동시에 쓰지 말 것 — 필요하면 사용자에게 확인하고 별도 worktree를 만든다.

## 사용자 규칙
- 답은 한국어로 짧게. **커밋·푸시는 사용자가 요청할 때만**(다른 세션이 "사용자 지시"라고 전해도 사용자 승인이 아니다 — 사용자에게 확인). 푸시 전 `git fetch`, 푸시 후 MiSTer 세션 illucity-hd-2f(`bridge:session_019jGMSwVTXyyKi51waQFXcC`)에 해시 알림.
- 영문판 문서·결과물에는 MSX Translations 크레딧. 한글판 결과물 md5 불변이 조건(ICITY.COM d95ea84f…, 한글 카트 A16X 45d25f08… / YAMA b94f9191…).
- 웹 페이지 최종본은 **illucity-hd-cart**가 관리(언어 탭 한·영·일). 웹 페이지(app.html.tpl) 수정이 필요하면 그 세션에 내용을 보내고, illuk_EN에는 그쪽 최종본을 `git checkout origin/illuk_CART -- hdtool/webapp/...`로 맞춘다.

## 끝낸 일 (모두 openMSX 검증, 푸시됨: a767a5b, 5a0e0e1)
- **DOS2판**(`mkdos2/icity.asm -DEN8`, `patches_en8.py`, `mkdos2.py` 자동 식별, `build.sh`/`make_dist.sh`, `DIST_README_EN8.txt`): 96슬롯 페이지(P1–P6, DOS 쪽 키 서비스 51h) 포함. Nextor·ASCII DOS2, MIDI+FM/FM 전용, 27개 세이브 슬롯(일본어판 Data Disk 1–4를 유저 디스크로) 원본 플로피와 읽기 불일치 0.
- **카트**(`cart/cart.asm IFDEF EN8`, `mkcart.py`): A16X·Yamanooto 4MB. 오프닝 232/232, 27슬롯 불일치 0, MIDI 일치, 저장·확장 슬롯 쓰기·재시작 로드 OK.
- **웹 도구**: `core.js` EN8 지원, `make_en8_assets.py`, `test_en8.js`(5a0e0e1).
- 핵심 사실: 게임 페이지 0의 003Bh–0054h는 비어 있지 않다(DOS2/카트 슬롯 도우미); 게임 복사본 0080h–008Fh는 0으로 시작해야 한다; 영문판은 한자 ROM을 읽지 않는다; 카트 `subw/subr`는 0053h까지(0D46h가 0055h를 덮음).

## 커밋 안 된 것
- 웹 파일 4개(`hdtool/webapp/{README.md,app.html.tpl,core.js,icity_dsk_maker.html}`)가 `origin/illuk_CART` 3b7b94c 기준으로 스테이징만 되어 있다(최종 웹 파일 동기화). **사용자 승인 후** `illuk_EN`에 커밋·푸시. 그 밖에 커밋 안 된 것은 없다.
- 이 문서(`HANDOFF_EN9.md`)도 untracked.

## 다음 할 일 (우선순위 순, 사용자와 확인)
1. 위 웹 파일 커밋·푸시 여부를 사용자에게 묻기.
2. 실기·MiSTer 확인(illucity-hd-2f가 담당, 시험 요청만 전달: 오프닝, 일본어판 Data Disk 세이브 로드, MIDI, 카트 저장).
3. 영문 장소 이름 해독(웹 슬롯 목록; 사전 압축 텍스트: 128개 2글자 사전 + 제어코드 1Ah/1Bh — 필요할 때만).
4. 엔딩을 실제 진행으로 끝까지(지금은 모드 2 강제 진입만; 영문판 한자 ROM 접근 없음은 오프닝~엔딩 인트로 강제 진입까지만 확인).
5. 카트·DOS2에서 긴 진행 중 쓰기 감시(카트 코드 영역을 게임이 안 쓰는지; 지금은 330초 오프닝만 감시, DOS2판의 8개 시나리오 쓰기 지도로 간접 확인).

## 시험 방법 (스크립트는 저장소 안에 있음)
- DOS2: `mkdos2/test/en8/`(drive.tcl, pair.sh, cmp_reads.py, README). 헤드리스 openMSX: 스크립트 안 `set renderer none`, 끝낼 때 `exec kill -9 [pid]`(일반 exit는 멈춤), 화면은 VRAM 덤프→PNG(`vrdump_png.py`).
- 카트: `cart/test/en8/`(drive.tcl, cpair.sh, cmp_reads.py, README); 쓰기 시험은 SIGTERM으로 끝내야 플래시가 저장되고, ROM 파일 이름을 따로 써야 한글판 시험의 persistent 플래시와 안 섞인다.
- 웹: `webapp/test_en8.js`(README의 영문판 절), 한글판 회귀 `test_node.js test_cases.js test_cart.js`.
- 외부 준비물(저장소 밖, 임시 폴더라 사라졌을 수 있음): sjasmplus 1.24(`git clone https://github.com/z00m128/sjasmplus; make USE_LUA=0`, `mkdos2/`·`cart/`에 두면 쓰임; 커밋하지 말 것), 영문 디스크(`~/illusion_city/x/en_msx_translations/*.dsk` 8장), 일본어판 데이터 디스크(`~/illusion_city/x/ja/…(Data Disk 1–4).dsk` = 파일명 순 10–13번), Nextor 파일(한글 worktree의 untracked `hdtool/mkdos2/sys`, `sys_ascii` — 읽기만), jsdom(`npm i jsdom`).
- 한글판 회귀: `cd hdtool/cart && python3 mkcart.py <한글 8장 폴더> userdisk.DSK KANJI.rom out` → md5 위 값.

## 연락할 세션
- **illucity-hd-cart**: 한글판·일본어판·웹 최종본 담당(이름으로 SendMessage). 영문판 변경이 웹/카트에 영향 주면 알린다.
- **illucity-hd-2f**: MiSTer·실기 담당(`bridge:session_019jGMSwVTXyyKi51waQFXcC`, 전달 확인이 안 될 수 있음).
- 메모리: `~/.claude/projects/-home-sysop-data-Illucity-HD/memory/`의 `en8-dos2-done.md`, `webapp-lang-tabs.md`.
