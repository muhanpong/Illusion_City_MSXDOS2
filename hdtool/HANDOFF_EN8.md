# 인수인계 — 영문 8장판(MSX Translations) DOS2·카트 작업, 2026-10-03

새 세션은 이 문서 → `hdtool/PLAN_EN8.md`(계획, 적대적 검토 반영·검수 완료) → `hdtool/HANDOFF_NEXT.md`(사용자 규칙·한글판 상태) 순서로 읽는다.

## 사용자 규칙 (요약, 자세한 것은 HANDOFF_NEXT.md 0절)
- 답은 한국어로 짧게. 커밋·푸시는 사용자가 요청할 때만. 저자는 저장소 git config.
- 웹 도구 `hdtool/webapp/`는 네 브랜치(master, nextor_emu, msxdos2, illuk_CART)에 같은 내용(영문 브랜치 포함 여부는 S10에서 결정).
- 푸시 전 fetch, 푸시 후 MiSTer 세션 illucity-hd-2f(`bridge:session_019jGMSwVTXyyKi51waQFXcC`)에 해시 알림.
- 한글판은 키티야 님(번역·글꼴·인코딩)께 드리는 작업. 영문판 문서에는 MSX Translations 크레딧.

## 지금 상태
- 작업 위치: **worktree `/home/sysop/data/Illucity_HD-en`, 로컬 브랜치 `illuk_EN`**(upstream 없음 — 첫 푸시 때 사용자 확인 후 `-u origin illuk_EN`). msx1-tmux가 origin/master d16cd5a에서 만들었지만 master에는 `mkdos2`·`cart`가 없다 → **커밋이 없을 때 illuk_CART `56e978b`로 맞춘다**(`git reset --hard 56e978b`, 새 worktree라 잃을 것 없음).
- 한글판 worktree `/home/sysop/data/Illucity_HD`(illuk_CART)는 건드리지 않는다. 이 문서와 `PLAN_EN8.md`는 그쪽에서 미커밋으로 만들어졌으니 `illuk_EN` worktree로 복사해 첫 커밋에 넣는다.
- 계획 단계 S1(원본 실행 기록·빈 곳 측정)부터 시작할 차례. 아직 빌드·실행 시험은 없음(바이트 비교·역어셈블만).

## 자료 위치 (모두 저장소 밖)
- 영문 8장판: `~/illusion_city/x/en_msx_translations/*.dsk` (zip 원본 `~/illusion_city/en_msx_translations/`)
- 영문 6장판(디스크 7·8 없음, 지원 안 함, 판 식별 시험용): `~/illusion_city/x/en_translation/`
- 한글판 원본: `/home/sysop/data/Illucity_HD/illucity_K.zip`(풀어 둔 것 `/tmp/kz/`), `userdisk.DSK`, `KANJI.rom`
- 이전 세션 분석 파일(임시, 지워질 수 있음): `/tmp/claude-1000/-home-sysop-data-Illucity-HD/805c0083-1f9e-4b08-a0dd-41d8ac2f8dee/scratchpad/`
  — `cmp.js`(core.js로 판별 청크 비교), `review/`(검토 에이전트의 역어셈블·cart 재조립 listing `cb/cart.lst`)

## 범위
영문 8장판 DOS2판·카트 제작만. 한글판 후속(세이브 변환기, 카트 플로피 백업 등)과 일본어판은 이 작업에 넣지 않는다(원래 세션 illucity-hd-cart 담당).
