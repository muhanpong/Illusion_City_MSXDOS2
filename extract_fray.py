import struct
import os

# =======================================================
# 설정: DSK 파일 경로를 정확히 입력해주세요.
# =======================================================
DSK_FILE_PATH = "I-City(k)(8-8).dsk" 
OUTPUT_DIR = "extracted_fray_files"

# FRAY DOS 시스템 상수 (분석 결과 확정)
DIR_ENTRY_START = 0x0E00   # 디렉터리 영역 시작
CLUSTER_SIZE = 1024        # 1 클러스터 = 1KB
DATA_OFFSET = 0x1400       # 데이터 시작 위치 (5120 바이트)

def extract_files(dsk_path, output_dir):
    if not os.path.exists(dsk_path):
        print(f"오류: '{dsk_path}' 파일을 찾을 수 없습니다.")
        return

    if not os.path.exists(output_dir):
        os.makedirs(output_dir)
        print(f"폴더 생성: {output_dir}")

    with open(dsk_path, "rb") as f:
        # 전체 파일 크기 확인 (범위 초과 방지용)
        f.seek(0, os.SEEK_END)
        disk_size = f.tell()
        
        # 디렉터리 영역으로 이동
        f.seek(DIR_ENTRY_START)
        
        print(f"{'파일명':<12} | {'크기(Bytes)':<10} | {'위치(Hex)':<10} | {'결과'}")
        print("-" * 60)

        while True:
            # 32바이트 단위로 엔트리 읽기
            entry_data = f.read(32)
            
            # 더 이상 읽을 게 없거나, 파일명이 00으로 시작하면 종료
            if not entry_data or entry_data[0] == 0x00:
                break

            # 파일명 (0~8), 확장자 (8~11)
            name = entry_data[0:8].decode('latin-1', errors='ignore').strip()
            ext = entry_data[8:11].decode('latin-1', errors='ignore').strip()
            
            # FRAY DOS 등 시스템 라벨이나 빈 항목 건너뛰기
            if not name or name.startswith(('\x00', '\xff')):
                continue

            full_name = f"{name}.{ext}" if ext else name

            # === [수정된 핵심 부분] ===
            # 시작 클러스터: 오프셋 26 (0x1A), 2바이트
            # 파일 크기: 오프셋 28 (0x1C), 4바이트 (안전하게 4바이트로 처리)
            start_cluster = struct.unpack_from("<H", entry_data, 26)[0]
            file_size = struct.unpack_from("<I", entry_data, 28)[0]

            # 파일 크기가 0이거나 비정상적으로 크면 스킵 (유효성 검사)
            if file_size == 0 or file_size > disk_size:
                print(f"{full_name:<12} | {file_size:<10} | {'-':<10} | 스킵 (크기 0 또는 오류)")
                continue

            # 실제 데이터 위치 계산
            # 공식: (클러스터 번호 * 1024) + 5120
            file_offset = (start_cluster * CLUSTER_SIZE) + DATA_OFFSET
            
            # 범위 체크
            if file_offset + file_size > disk_size:
                print(f"{full_name:<12} | {file_size:<10} | {file_offset:06X}     | 오류: 범위 초과")
                continue

            # 데이터 추출 및 저장
            current_pos = f.tell() # 현재 디렉터리 위치 기억
            
            f.seek(file_offset)
            file_data = f.read(file_size)
            
            save_path = os.path.join(output_dir, full_name)
            with open(save_path, "wb") as out_file:
                out_file.write(file_data)
            
            print(f"{full_name:<12} | {file_size:<10} | {file_offset:06X}     | 성공")
            
            f.seek(current_pos) # 다시 디렉터리 위치로 복귀

    print("-" * 60)
    print("추출 작업이 완료되었습니다.")

# 실행
extract_files(DSK_FILE_PATH, OUTPUT_DIR)
