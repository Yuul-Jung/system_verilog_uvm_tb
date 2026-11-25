# 제06장 v03 검증 기록

## 원본 매칭
- amd_soc_npu 제1장 UART 계산기 03절 서브젝트 1-1 UART 에코, p01_uart_calc_v01.html (f1089413362a271717b6a4b6a2e95deb569334f2).
- 원본 스냅샷 28160c34522e47fbd961466651598da063bc74ae, 현행 common/rtl/uart_echo_controller.v 76269e771295fadcd0ddf160bee4556fdfa62e56. 직접 조회한 두 코드의 주석 행 제외 본문 동일. RTL 원본 변경 없음.
- 패키지 uart_expect_pkg.sv 원본 d88f99e4d9a6ec5dd330aab862c31db752ea25be 변경 없음. TB 및 스크립트만 호환성/관찰 보완.

## 수정
- 전체 RTL, 패키지, TB와 독립 폴더 준비, 컴파일 순서 및 XSIM/Icarus 실행 경로 제공. 수업 시간 배분 제거.
- 제05장과 제06장의 uart_sample_t 필드 순서 차이(data,valid,ready vs valid,ready,data)를 명시. 제06장 valid[9],ready[8],data[7:0] 순서 보존.
- 6개 위치 지정 구조체 대입 패턴을 동일 폭의 10비트 연결 표현으로 대체. 호환성 목적의 표현 변경이며 실제 컴파일 성공은 미확인. 기존 입력과 비교 동작 유지.
- TB의 VCD 조건부 기록, 시간 로그 %0d ns 및 스크립트 -DVCD 적용. TB 022077dec2d4a7c84d5fbf0b659fe78a8a94d053, 스크립트 77bdf1a3ddfdc7a801f189d6feb631a7ed276790.
- 입력의 valid/ready로 수락 사례를 모델링하고 실제 출력 3개를 별도 검사함을 명시. 실제 DUT는 클록과 FIFO가 없는 조합 연결이다.
- Icarus 버전에 따라 다차원 packed 배열 가변 인덱스 및 큐 지원이 다를 수 있음을 명시.

## 독립 계산 (실측 아님)
| 관찰 ns | 사례 | valid | ready | 큐 제거 | 남은 기대값 |
|---:|---|---:|---:|---|---|
| 1 | IDLE | 0 | 1 | 없음 | A B C D |
| 2 | SEND A | 1 | 1 | A | B C D |
| 3 | STALL B | 1 | 0 | 없음 | B C D |
| 4 | RESUME B | 1 | 1 | B | C D |
| 5 | SEND C | 1 | 1 | C | D |
| 6 | SEND D | 1 | 1 | D | 비어 있음 |

- 6개 신호 묶음 비교 + 4개 데이터 비교 + 최종 큐 검사 1 = 11회, 예상 실패 0. 배열 역순 및 대기 중 제거 반례는 논리 검토이며 실제 변이 실행 아님.
- SVG 단독 Chromium 렌더에서 초안 텍스트 겹침 4쌍 발견. 첫 행을 한 줄로 수정 후 텍스트 23개, 겹침 0, viewBox 초과 0. 스크린샷 확인 및 원격 SVG Blob 11adc7822c21da085ea0bda349f8954744679e7f 동일. 데이터 배치도이므로 편집기 flow JSON 미제작.
- 원격 HTML 2aaded6afd91e7131d362e86ccc3b28e58e55d87: 전체 RTL/패키지/TB 문자 비교 일치, 8절, 24장 탐색 및 INDEX 링크, 중복 ID 없음, 배포 독립성 정적 검사 PASS.

## 검증 상태
- 원본 및 코드 일치, 독립 큐 모델, SVG 단독 렌더, 원격 정적 검사: PASS (각 범위에 한함).
- RTL_SIM(XSIM/Icarus): NOT_RUN — 실행 명령 부재.
- 전체 HTML·모바일·Pages 실제 접속: NOT_RUN.
