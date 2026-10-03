# S1 측정 기록 (영문 8장판, openMSX 21.0 Panasonic_FS-A1GT, 헤드리스, 2026-10-03)

실행: `T=out D=<D1..D8.dsk,DU.dsk 폴더> SONG=song1.tcl SOUND=0 MAIN=2 END=1500 WSTART=480 WANDER=1
SDL_VIDEODRIVER=dummy SDL_AUDIODRIVER=dummy openmsx -machine Panasonic_FS-A1GT -script run_en.tcl`
(`run_en.tcl` = `fdd/test/run.tcl` + `set renderer none` + 메인 메뉴 IX 8368h(한글판 836Eh). 화면 없이 돌고 스크린샷은 못 찍는다.)
`song1.tcl`은 t>26s에서 쓰기 감시(E941–E96E, E96F–E9FF, DD00–DD91, DF7E–DFFE, 0003–0054, 0055–007F, 0090–00FF, FB30–FCAF)와 한자 ROM 포트 D8–DB 쓰기, F37D 호출을 기록한다.

## 확인된 것
- 영문판 디스크 1이 부팅되어 사운드 메뉴(IX 8338h)→메인 메뉴(IX 8368h)까지 간다. 메뉴 루틴 3AEFh/308Ah, 디스크 확인 호출(F37D C=2Fh DE=0 ret=5BAEh), 확인 루틴 5B48h(라벨 `IPROJ0n` 비교)는 한글판과 **같은 주소**.
- 디스크 번호 변수 (5EC0h)도 같다: 오프닝 때 값 1 → 디스크 2 자동 교체가 한글판 `run.tcl`로 그대로 동작.
- 시작(MAIN=2 오프닝) → 디스크 2 → 가상 시간 1500초(메뉴 3BFEh/46B9h/6412h까지)까지, t>26s에 **감시 구역 쓰기 없음**
  (DF88h 한 번은 DF7Eh 블록 자기 코드 PC=DF8B). **한자 ROM 포트 D8h–DBh 쓰기 0회**(오프닝~디스크 2 구간).
- t<26s(부팅·로더 단계): E975h에 PC=5F56이 00 쓰기(한 번), DD56h–DD91h는 로더·스택으로 쓰임 → **DD30h–DD55h(38바이트)만 쓰이지 않는 후보**. E96Fh–E9FFh는 이 구간에서 E975h 외 비어 있음(스택 쓰기 제외).
  (측정 구간이 오프닝뿐이다. 세이브 로드·디스크 4–6·엔딩 인트로는 아직.)
- 커널 E000h 점프 표와 진입 E04Bh는 한글판과 같은 형태: 모드 (0081h)×3 + 표 E8CEh(한글판 E908h).

## 막힌 것 / 다음
- 모드 2 강제 진입(`fdd/test/mode2.tcl` 방식)을 메인 메뉴 상태(t=40s)에서 하면 파일 14를 읽은 뒤(79DBh 부근 루프) SP가 망가져 폭주한다(t≈41.36s SP=457Ch). 한글판 시험 상태와 다르다 — 진입 시점·초기 상태를 다시 찾아야 한다. G2(한자 ROM 읽기) 호출 여부는 미확인.
- 세이브 로드(MAIN=1): 영문판 디스크 1·유저 디스크에 영문 세이브가 없다(한글 세이브는 호환 미확인). 영문판으로 새로 세이브를 만들어야 한다.
- MIDI(SOUND=1) 기록, 섹터 284–299 사용처, 디스크 3·4·5 파일 14 크기는 아직.

## 추가 (같은 날, 2차)
- **모드 2 진입은 t=30s(메인 메뉴 직후, 키 입력 전)에 하면 성공**: 파일 14가 8000h에 올라 엔딩 인트로가 가상 400초 넘게 돈다
  (섹터 0431h~ 연속 읽기, 5800h 읽기 등). t=40s·500s·1400s 진입은 SP가 깨져 폭주 — 시점 의존.
- 이 구간에서 **감시 구역(E941–E9FF, DD00–DD91, 페이지 0, FB30–FCAF) 쓰기 0회, 한자 ROM 포트 D8h–DBh 접근 0회**
  (부팅 0.58s의 BIOS 접근만 있음; 감시는 VDP 포트 대조군으로 동작 확인). ADFEh(G2 자리)는 도달하지 않음 → **G1·G2는 영문판에서 필요 없을 가능성이 높다**(S6; 엔딩 인트로 전체를 진행한 기록은 아님).
- 한글판 유저 디스크 세이브 로드(MAIN=1 MED=4 SLOT=0): 메뉴 5C19h·5C86h는 영문판에서도 같은 IX. 디스크 U 삽입까지 진행, 이후 섹터 읽기 결과는 미정리.
- 참고 자료: `~/illusion_city/x/ja/`에는 일본어판 데이터 디스크 4장(Data Disk 1–4, 10–13번)이 있다(FAT 파일 없음, 부트 `MSX_04  `/`SNYJX102`).
- 한글 유저 디스크(DU)로 세이브 로드(MAIN=1 MED=4): 디스크 U 삽입(38s) 뒤 F37D 호출이 더 없고 900s까지 진행 없음 → 영문판이 한글판 유저 디스크의 세이브를 받아들이지 않거나 다른 확인에서 멈춘 것으로 보임(원인 미조사). 디스크 4–8 구간 기록은 영문판으로 직접 세이브를 만들어야 가능.

## 3차: 시작점 진행·세이브 위치 탐색
- 화면을 못 찍으니 `song11b.tcl`의 `dumpv`로 VRAM(SCREEN 5, 페이지 0)을 덤프해 `vr.py`로 PNG 변환해서 본다. `go.sh`+`bot.tcl`+`song13.tcl`: 키·대화 메뉴 자동 진행(메뉴 유무와 커서는 VRAM 픽셀 (200,4)=12 / (150,14·26·38)=13으로 판별). 실행은 결정적이라 같은 입력이면 같은 시각에 같은 화면.
- MAIN=3(시작점)은 디스크 2로 바로 가서(33s) 이름·준비 후 ~1100s에 필드 화면, 메이홍과 대화(메뉴: Finish talking / Reason for visit / Talk about the girl — 모든 주제를 해야 끝낼 수 있음, "I've not finished talking yet!"). 이어서 다음 대화(… Talk about SIVA), 1230s쯤 필드 조작 시작.
- 필드 명령 팝업(스페이스): Magic / Items / Equipment / Discuss / Status / Settings → Settings: Adjust Speed / Switches / BGM / **Load**(Save 없음). 한글판 README처럼 세이브는 게임 안 터미널(천인의 아파트)에서 한다(한글판도 실제 게임 저장은 미확인, 주입 시험만).

## 4차: 일본어판 데이터 디스크(Data Disk 1–4)로 영문판 로드 — 전부 됨
`~/illusion_city/x/ja/`의 Disk 10–13(Data Disk 1–4)은 세이브가 든 유저 디스크. 복사본을 `DU.dsk`로 넣고 `one_en.sh <데이터디스크 1-4> <슬롯 1-8> <END> "<덤프 시각>"`
(run_en.tcl, MAIN=1 MED=4, SLOT은 1부터). **영문판 8장에서 27개 슬롯 모두 로드·진입**, 요청 게임 디스크가 한글판 결과와 같다.
메뉴 IX 5C19h·5C86h도 영문판과 같다. 슬롯 목록(영문 장소명)은 약 41s의 VRAM(`vr.py`)에서 읽는다.

| 데이터 디스크 | 슬롯: 레벨 장소 → 들어가는 게임 디스크 |
|---|---|
| 1 | 1: L1 Tian Ren's Apartment→2 / 2: L4 Kowloon District→3 / 3: L5 Kowloon District→3 / 4: L6 Western District→3 / 5: L6 SIVA HQ Building→3 / 6: L8 Tian Ren's Apartment→2 / 7: L8 Sai Kung District→4 / 8: L9 Shu Luo area→4 |
| 2 | 1: L10 Tian Ren's Apartment→2 / 2: L11 Shu Luo area→4 / 3: L13 Tian Ren's Apartment→2 / 4: L14 Tiu Chung area→5 / 5: L15 Tian Ren's Apartment→2 / 6: L16 Tiu Chung area→5 / 7: L17 Tian Ren's Apartment→2 / 8: L17 Cheung Lung area→5 |
| 3 | 1: L23 Floating City→6 / 2: L24 Underwater City→6 / 3: L25 Sha Tin area→7 / 4: L30 Bio Laboratories area→7 / 5: L31 Sha Tin area→7 / 6: L32 Doc's Store→2 / 7: L32 Sha Tin area→7 / 8: L34 Inside Illusion Castle→8 |
| 4 | 1: L34 / 2: L35 / 3: L36 모두 Inside Illusion Castle→8 (4–8 빈 슬롯) |

## 정정 (DOS2판 작업 중 확인)
- 위의 "페이지 0 빈 곳"은 영문판 **원본 플로피**만 본 것이다. DOS2판에서는 003Bh–0054h에 DOS2 페이지 0 이미지의 슬롯 전환 도우미가 복사되어 있어 쓸 수 없다(상세: `PLAN_EN8.md` 진행 상태, `mkdos2/test/en8/README.md`).
