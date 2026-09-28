# Illusion City (K) — FS-A1GT HD 실행 계획

## 1. 디스크 포맷 분석 결과

| 항목 | 내용 |
|---|---|
| 물리 포맷 | 표준 720KB, FAT12 BPB. 단 FAT 전체가 0xFF7(불량 클러스터)로 채워져 DOS에서는 파일이 안 보임 |
| 부트 | 부트섹터가 FCB로 `FRAY.DOS`(Microcabin FRAY DOS, Y.Nakatsu 1991)를 0x100에 로드 |
| FRAY.DOS | 0x100–0x35A 로더 + E000–E946 상주 커널(점프테이블 E000–E048) |
| 파일 테이블 | 섹터 11: 파일 번호별 (시작섹터, 섹터수) 2바이트 쌍. 커널이 EA00에 읽음 |
| 디스크 I/O | 전부 BDOS `F37D` 기능 2Fh(절대 섹터 읽기)/30h(쓰기), L=0(A:), DE=섹터, H=개수 |
| 디스크 확인 | 엔진 파일 9의 0x5B48: 섹터 0 라벨(+3) `IPROJ0n` 비교 → 0..7 = 디스크1..8, 10 = 유저디스크. 원하는 디스크 번호는 (0x5EC0) |
| 세이브 | 디스크1 또는 유저디스크의 섹터 0x578+2n (8슬롯), 기능 30h로 기록 |
| 코드 위치 | Z80 코드는 디스크1 파일 0–14에만 있음. 디스크2–8은 INF(파일6)+시나리오(파일14)+데이터 |

## 2. MSX-DOS2 개별 파일 방식이 막히는 이유

- 게임이 E000–F37F, F400–F7FF, 0x80–0x8F를 직접 사용한다. DOS2/Nextor DOS2는 이 영역(TPA 상단 ≈ DC06)을 차지한다.
- 따라서 DOS2 위에서 파일 단위로 읽게 하려면 커널 재배치와 엔진 전반의 메모리 맵 수정이 필요하다. 엔진 재작성 수준이다.
- 대안: Nextor **디스크 에뮬레이션 모드**(EMUFILE). ROM만 쓰는 DOS1 모드로 부팅하므로 원본과 같은 메모리 환경이 된다.

## 3. 채택한 방식

1. `build_icity_hd.py`가 디스크 1–8과 유저디스크를 이어 붙여 `ICITYHD.DSK`(6.5MB 단일 FAT12 이미지) 생성.
   - 디스크1 BPB를 12960섹터, 클러스터 16섹터로 고침(FAT 3섹터 이하라 DOS1 호환).
   - 유저디스크 영역은 `I-City(k)(U).dsk`(기존 세이브) 내용을 사용하고 라벨만 `USERDISK`.
2. `hook.asm`(sjasmplus)를 FRAY.DOS 끝(0xDA2)에 붙이고 첫 명령을 설치 루틴으로 점프.
   - 106바이트 훅을 0x0090에 복사하고 `F37D` 점프를 가로챔.
   - 기능 2Fh/30h, 드라이브 A:이면 섹터에 (현재디스크−1)×1440을 더함.
   - 섹터 0 읽기(디스크 확인) 때 (0x5EC0)을 보고 현재디스크를 자동 전환. 디스크 교체 화면 없이 진행.

## 4. 실기(FS-A1GT) 설치 절차

전제: HD 인터페이스가 **Nextor 2.1 이상 커널**이고 1차(primary) 컨트롤러일 것. EMUFILE 조건이다.

```
A:> MD ICITY
A:> CD ICITY
(ICITYHD.DSK, EMUFILE.COM 복사)
A:\ICITY> EMUFILE ICITY.EMU ICITYHD.DSK
A:\ICITY> EMUFILE SET ICITY.EMU        ← 1회용, 자동 리셋 후 게임 부팅
A:\ICITY> EMUFILE SET ICITY.EMU P      ← 영구 모드, 부팅 때 0 키로 해제
```

- `ICITYHD.DSK`는 조각나지 않아야 한다. 파티션을 막 포맷했거나 여유가 많을 때 복사한다. EMUFILE이 "Checking FAT chain ... Ok!"로 확인한다.
- 이미지 교체 키(1–9)는 쓰지 않는다. 디스크 전환은 훅이 한다.
- 세이브는 이미지 안(디스크1 또는 유저디스크 영역)에 기록된다.

재생성:
```
sjasmplus hook.asm            # hookpatch.bin
python3 build_icity_hd.py <원본 dsk 폴더> ICITYHD.DSK
```

## 5. 검증 현황 (openMSX, FS-A1GT 한글폰트 머신 + Sunrise IDE Nextor 2.1.2)

| 항목 | 결과 |
|---|---|
| EMUFILE 등록/부팅 | 통과. FAT chain Ok, 자동 리셋 후 FRAY.DOS 로드 |
| 타이틀·오프닝 | 통과 |
| 스타트 지점부터 시작 → 디스크1→2 자동 전환 → 게임 화면 | 통과 (섹터 0 확인 후 cur=2, 디스크2 섹터 계속 읽음) |
| 유저디스크 슬롯 읽기(0x578–0x586) | 통과 (cur=9 영역에서 읽음) |
| 세이브 쓰기(30h) 후 다시 로드 | **미검증** |
| 디스크 3–8 전환 | **미검증** (같은 경로라 동작 예상) |
| 실기 FS-A1GT | **미검증** |

## 6. 남은 확인 순서

1. 게임 안에서 유저디스크에 세이브 → 리셋 → 로드.
2. 디스크1 슬롯에 세이브/로드.
3. 후반 디스크까지 진행(또는 세이브 데이터로 점프)해 3–8 전환 확인.
4. MIDI 음원 선택 시 동작(ARMI 계열 드라이버와 무관한지).
5. 실기에서 1–4 반복.

## 파일

- `build_icity_hd.py`, `hook.asm`, `EMUFILE.COM`(Nextor tools v1.1), `ICITYHD.DSK`(생성물)
- `openmsx_emutest.tcl`: 에뮬레이터 자동 테스트 스크립트
- `analysis/`: FRAY.DOS 로더·커널 역어셈블, 인트로 구간 page3 사용 지도
