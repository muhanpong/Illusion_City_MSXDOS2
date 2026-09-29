# 카트리지판(Yamanooto / ASCII16-X) 인수인계 — 2026-09-29

목표: **카트리지만 꽂으면 부팅되는** 환영도시(ILLUSION CITY) ROM. 대상 매퍼 두 가지(사용자가 실기 둘 다 보유).
DOS2판(`hdtool/mkdos2`, 배포 zip, 웹앱)은 완료 상태이며 이 작업과 별개다.

## 1. 확정된 사실

### 매퍼 (openMSX 소스 `src/memory/Yamanooto.cc`, `RomAscii16X.cc` 기준)
| | Yamanooto (`-romtype Yamanooto`) | ASCII16-X (`-romtype ASCII16-X`) |
|---|---|---|
| 플래시 | 8MB (S29GL064N) | 8MB (S29GL064S) |
| 뱅크 | 8KB × 4 (4000/6000/8000/A000), 0000↔8000·C000↔4000 미러 | 16KB × 2 (4000·C000 / 8000·0000) |
| 전환 | Konami-SCC식: 5000h/7000h/9000h/B000h (값 8비트) | 6000h-6FFFh(첫 뱅크)/7000h-7FFFh(둘째), 12비트 = 주소 bit8-11 + 데이터 |
| 8비트 한계 | 뱅크 = (값 + offset) & 3FFh, offset = OFFR(7FFEh)<<2. OFFR는 ENAR(7FFFh)=01h(REGEN)일 때만 쓰기. 7FFC-7FFF는 미러 안 됨(페이지 1에서만) | 없음 |
| 리셋 | bankRegs = 0,1,2,3 → 4000h에 ROM 첫 16KB | 0,1 → 4000h에 첫 16KB |
- 데이터 6.6MB(디스크 8장 5.6MB + 유저 디스크 0.7MB + FONT 0.25MB) → 8MB에 압축 없이 들어감.

### 부팅 경로 (openMSX FS-A1GT, `kittya`, 시험 ROM `probe.asm`)
- 카트리지 INIT은 4.9초에, **H.STKE(FEDAh) 훅은 디스크 커널 초기화 후 10.6초**에 불린다(F37D=`C3 31 F3` 준비됨). 두 매퍼 모두 같다.
- 단 이 시점엔 DOS 실행 환경(페이지 0 RAM의 RDSLT/CALSLT/ENASLT 진입점, 페이지 3의 DD92h~DF7Dh 루틴, F36B=`C3 41 DF`)이 **아직 없다**. 원본 부트 섹터가 이 환경을 쓴다.
- 디스크 ROM의 부팅 루틴(뱅크 매핑된 디스크 ROM 59F3h~5AE4h): `5AE7h`에서 **BIOS PHYDIO(0144h)로 드라이브 A 섹터 0을 읽어** C000h로 복사, 첫 바이트 EBh/E9h 확인 → `C01E` 호출(CF=0) → **DOS 환경 설치**(59FE~5AD7: 페이지 0 이미지, DD92h 루틴, 0038h, F36B 점프표) → `SCF; JP C01E`(CF=1).
- PHYDIO는 **H.PHYD(FFA7h)** 훅을 거친다. ⇒ **카트리지가 H.PHYD를 잡고 "드라이브 A, 섹터 0" 읽기에 부트 섹터를 내주면**, 디스크 ROM이 원본과 똑같은 환경을 만든 뒤 우리 부트 코드를 CF=1로 부른다. (아직 구현·검증 안 함)
- 원본 부트 섹터가 `JP 0100` 직전 만든 상태(원본 측정): A8=FFh, 서브슬롯 00h(전부 3-0), 매퍼 FC-FF=3,2,1,0, SP=FAF8h, IFF=1, Z80 모드, 0080h-0087h=`00 00 00 98 98 23 F3 00`, F37D=`C3 31 F3`.

### 게임이 쓰는 것 (원본 측정)
- 게임은 실행 내내 CALSLT/ENASLT/RDSLT를 많이 쓴다(메인 BIOS/서브 ROM/MSX-MUSIC/디스크 ROM DSKIO 대상). 페이지 0 RAM의 진입점 → 페이지 3 DDxxh 루틴(디스크 ROM이 설치한 DOS1 환경 코드)을 통해서다. 그래서 위 H.PHYD 경로로 **디스크 ROM이 환경을 만들게 하는 것**이 핵심.
- 디스크 ROM 대상 호출은 DSKIO(4010h)뿐이고, F37D(1Ah/2Fh/30h)를 가로채면 사라진다.
- 페이지 3에서 게임이 **읽지도 쓰지도 않는 것으로 확인된 곳: E947h~E9FFh(185바이트)** (MIDI 400초 + FM 세이브 로드 300초씩, `phase0/watchfree`).

## 2. 설계 (합의된 방향)
1. ROM 첫 16KB: 헤더 `AB`, INIT(자기 슬롯 구해 H.PHYD 설정 — 필요하면 H.STKE에서 설정), H.PHYD 처리기(드라이브 0·섹터 0 → 부트 섹터 제공, 그 외 원래 처리기로), 부트 코드.
2. 부트 코드(C01E, CF=1, DOS 환경 있음): ENASLT(0024h)로 카트리지를 열어 **FRAY.DOS(디스크1 섹터 14~20)를 0100h에 복사**, F37D를 상주 처리기로 연결, 0080h-0087h 채우기, SP=FAF8h, `JP 0100`.
3. 상주 처리기(페이지 3): 1Ah=DTA 저장, 2Fh=읽기(L=0), 30h=쓰기(아래 세이브). 섹터 → ROM 오프셋 `DATA + ((디스크-1)*1440 + 섹터)*512`, 조각 표 없음. 섹터 0 읽기 때 (5EC0h)로 디스크 자동 전환(`hdtool/hook.asm` 논리 그대로). 창 페이지는 목적지와 안 겹치는 1 또는 2, ENASLT로 열고 닫기(확장 슬롯도 자동 지원).
4. 게임 쪽 패치: DOS2판의 L1/K1/INIT/K2/M1-M3는 **불필요**(512KB 매퍼를 원본처럼 전부 사용, MIDI 원본 그대로). 한글 폰트를 쓰면 G1(file7 2AB9h→래퍼)만 적용하고 글리프도 ROM에서 읽는다.
5. ROM 배치 안: 0000h 부트/코드(64KB 예약), 10000h부터 디스크 1~8 + 유저 디스크 연속(9×720KB), 그 뒤 FONT 256KB, 8MB로 패딩.

## 3. 막힌 곳 / 남은 일 (순서대로)
1. **상주 코드 자리.** E947h~E9FFh(185바이트)로는 빠듯함(예상 200~250바이트: Yamanooto OFFR 처리, 창 선택, 디스크 전환, 폰트).
   - 시도: 로더 진입(0100h, `21 5B 04`) 때 후보 영역(C000-DBFF, EC00-F2FF)을 76h로 채우고 플레이 → **게임이 초반에 멈춤**(화면 검정), 측정 무효. 어느 영역이 원인인지 영역별 분할 측정을 시작하다 중단(`scratchpad/pz/one.tcl` 방식: 2KB 단위 6개 영역을 각각 채우고 120초 진행).
   - 대안 A: 코드 축소(폰트 제외 등)로 185바이트에 맞추기.
   - 대안 B: 페이지 3엔 20~30바이트 발판만, 본 코드는 카트리지 ROM에서 실행. Yamanooto는 8KB 뱅크라 코드(8000-9FFF)와 데이터 창(A000-BFFF)을 한 페이지에, 목적지가 페이지 2면 페이지 1(4000-5FFF 코드 / 6000-7FFF 데이터). ASCII16-X는 16KB 뱅크라 코드와 데이터가 다른 페이지여야 해서 목적지 겹침 시 바운스 필요.
   - 권장: 빈 영역 측정을 먼저 끝내고(300바이트 이상이면 RAM 상주로 두 매퍼 공통), 안 되면 B.
2. **H.PHYD 경로 검증**: 시험 ROM에 H.PHYD 처리기 + 원본 부트 섹터(또는 최소 부트 코드)를 넣고, 드라이브에 디스크 없이 부팅해 C01E(CF=1)이 불리는지, 그때 페이지 0에 `C3 D7 DD`류가 있는지 확인. 확인할 점: 드라이브 A가 비었을 때 PHYDIO 전에 드라이브 준비 검사가 먼저 실패하지 않는지, 카트리지 슬롯의 H.PHYD 설정 시점(INIT에서 걸면 디스크 ROM INIT이 덮을 수 있음 → H.STKE에서 거는 것이 안전).
3. `cart.asm`(sjasmplus, `DEFINE MAPPER`로 두 변형) + `mkcart.py`(디스크·유저 디스크·폰트로 8MB 이미지 생성, G1 패치 선택) 작성.
4. openMSX 검증: `openmsx -machine kittya -carta ICITY_YAMA.rom -romtype Yamanooto -command "set firmwareswitch off"` (드라이브 비움). 오프닝 → 디스크 2 → 세이브 8개로 디스크 4~8. 한자 ROM 없는 표준 GT(`Panasonic_FS-A1GT`)에서 폰트판 확인.
5. **세이브**: ROM이라 30h 쓰기를 못 받음. 선택지 ① 게임 로드 메뉴의 "SRAM"(GT 내장) — 경로 미확인, ② 플래시 직접 쓰기(두 카트리지 모두 AMD 명령 방식 플래시; 섹터 지우기 필요, openMSX는 AmdFlashChip로 에뮬레이션·`sramname`에 저장), ③ 세이브 불가(로드만). 먼저 ①을 원본에서 확인.
6. 실기 확인: 사용자의 Yamanooto·ASCII16-X 카트리지. Yamanooto 실기는 자체 부팅 메뉴가 있을 수 있음(openMSX TODO: HOME/DEL 키).

## 4. 파일
- `hdtool/cart/probe.asm`: INIT에서 H.STKE/H.RUNC를 거는 16KB 시험 ROM(부팅 시점 확인용). `./sjasmplus probe.asm` → `probe.rom`.
- 측정 스크립트는 scratchpad에만 있음(`cb/run*.tcl`: 부팅 상태·H.STKE 시점·환경 설치 추적, `pz/*.tcl`: 페이지 3 빈 영역 측정). 필요한 것은 다시 만들 것.
- 참고: `hdtool/hook.asm`(Nextor판 F37D 훅: 디스크 자동 전환 논리), `hdtool/mkdos2/patches.py`(G1 패치 바이트), `hdtool/mkdos2/icity.asm`(glyph_wrap: 폰트 래퍼).
