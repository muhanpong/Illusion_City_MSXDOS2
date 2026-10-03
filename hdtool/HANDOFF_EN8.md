# 인수인계 — 영문 8장판(MSX Translations) DOS2·카트 작업, 2026-10-03

새 세션은 이 문서 → `hdtool/PLAN_EN8.md`(계획, 적대적 검토 반영·검수 완료) → `hdtool/HANDOFF_NEXT.md`(사용자 규칙·한글판 상태) 순서로 읽는다.

## 사용자 규칙 (요약, 자세한 것은 HANDOFF_NEXT.md 0절)
- 답은 한국어로 짧게. 커밋·푸시는 사용자가 요청할 때만. 저자는 저장소 git config.
- 웹 도구 `hdtool/webapp/`는 네 브랜치(master, nextor_emu, msxdos2, illuk_CART)에 같은 내용(영문 브랜치 포함 여부는 S10에서 결정).
- 푸시 전 fetch, 푸시 후 MiSTer 세션 illucity-hd-2f(`bridge:session_019jGMSwVTXyyKi51waQFXcC`)에 해시 알림.
- 한글판은 키티야 님(번역·글꼴·인코딩)께 드리는 작업. 영문판 문서에는 MSX Translations 크레딧.

## 지금 상태 (2026-10-03 갱신)
- 작업 위치: worktree `/home/sysop/data/Illucity_HD-en`, 브랜치 `illuk_EN`(origin/illuk_EN, 푸시된 것은 문서 커밋 946e8ef까지). 아래 구현은 **미커밋**(커밋·푸시는 사용자 요청 때).
- **DOS2판 완료·검증**: 자세한 결과와 정정 사항은 `PLAN_EN8.md` 맨 위 "진행 상태". 시험·재현은 `mkdos2/test/en8/README.md`.
  빌드: `cd hdtool/mkdos2 && ./build.sh <영문 디스크 폴더(D1..D8.dsk 또는 원래 파일명 + DU.dsk)> <출력>`(자동 영문판 인식, `sjasmplus`는 저장소 밖: v1.24를 `USE_LUA=0 make`로 빌드, Nextor 파일은 `sys/`),
  배포판: `./make_dist.sh <디스크 폴더> - <출력>`.
- 측정·분석 기록: `hdtool/phase0/en8/`(S1_NOTES.md, 헤드리스 VRAM 보기, 일본어판 데이터 디스크 27슬롯 표).
- 슬롯 96개 페이지, **카트(S9)도 구현·검증됨**(`cart/test/en8/README.md`; 빌드 `cd hdtool/cart && python3 mkcart.py <영문 디스크 8장 폴더> <유저디스크.dsk> - <출력>`). 다음: 웹 도구(S10), 실기·MiSTer 확인.

## 자료 위치 (모두 저장소 밖)
- 영문 8장판: `~/illusion_city/x/en_msx_translations/*.dsk` (zip 원본 `~/illusion_city/en_msx_translations/`)
- 영문 6장판(디스크 7·8 없음, 지원 안 함, 판 식별 시험용): `~/illusion_city/x/en_translation/`
- 한글판 원본: `/home/sysop/data/Illucity_HD/illucity_K.zip`(풀어 둔 것 `/tmp/kz/`), `userdisk.DSK`, `KANJI.rom`
- 이전 세션 분석 파일(임시, 지워질 수 있음): `/tmp/claude-1000/-home-sysop-data-Illucity-HD/805c0083-1f9e-4b08-a0dd-41d8ac2f8dee/scratchpad/`
  — `cmp.js`(core.js로 판별 청크 비교), `review/`(검토 에이전트의 역어셈블·cart 재조립 listing `cb/cart.lst`)

## 범위
영문 8장판 DOS2판·카트 제작만. 한글판 후속(세이브 변환기, 카트 플로피 백업 등)과 일본어판은 이 작업에 넣지 않는다(원래 세션 illucity-hd-cart 담당).
