# 제13장 v02 검증 기록

## 원본 매칭
- amd_soc_npu 제1장 UART 계산기 03절 서브젝트 1-1 UART 에코, p01_uart_calc_v01.html (f1089413362a271717b6a4b6a2e95deb569334f2).
- 현행 common/rtl/uart_echo_controller.v 76269e771295fadcd0ddf160bee4556fdfa62e56와 reference_rtl/uart_echo_controller.v 28160c34522e47fbd961466651598da063bc74ae 직접 대조: 첫 주석만 다름. 원본 RTL 변경 없음. 6포트, 3개 조합 연속 대입. 직렬 UART 및 FIFO는 검증 범위 밖.

## 적대적 검토 및 변경
- 기존 BFM은 예정된 수락 에지에서만 accepted를 증가시켰으므로, BFM 호출 외 추가 수락을 놓칠 수 있었다. 모든 상승 에지의 독립 모니터가 수락 수·순서·조합 포트 일치를 검사하도록 변경. BFM의 수락 조건은 유지하되 중복 집계 제거.
- previous_stall과 held_data를 사용하여 대기 표본 이후 다음 상승 에지의 데이터/valid 유지 확인. 표본 사이 글리치는 검사하지 않음.
- ready X에 Z 시험을 추가하여 두 값의 조합 전파와 확정 수락 제외 확인. 4상태 비교의 의도된 정상 결과이지 실제 직렬 프레이밍 오류 시험이 아님.
- TB 0063187be8f528197fd3d764a91a28816c52271f, 스크립트 1c346c1096ce54b0ff61e46b1b15b4a4567e070f. VCD 조건부 기록 및 -DVCD, DUT 경로 realpath 처리. Ubuntu XSIM 우선 및 Icarus 대체 실행. 실제 RTL/TB/스크립트 원문 및 독립 폴더 제공.

## 독립 샘플 계산 (실측 아님)
| 시간 ns | 데이터 | valid | ready | 예상 |
|---:|---|---:|---|---|
| 5 | 00 | 0 | 0 | IDLE |
| 15 | 41 | 1 | 1 | ACCEPT |
| 25 | 41 | 0 | 1 | IDLE |
| 35 | 5A | 1 | 0 | STALL |
| 45 | 5A | 1 | 0 | STALL |
| 55 | 5A | 1 | 1 | ACCEPT |
| 65 | 5A | 0 | 1 | IDLE |
| 75 | 0A | 1 | 0 | STALL |
| 85 | 0A | 1 | 1 | ACCEPT |
| 95 | 0A | 0 | 1 | IDLE |
| 105 | 45 | 1 | X | 미정 |
| 115 | 45 | 0 | 0 | IDLE |
| 125 | 46 | 1 | Z | 미정 |

- 131ns 종료 예상. 수락 3회, 대기 3회, X/Z 2회, 유휴 5회. expect_ports 14회(1+6+3+4), 상승 에지 모니터 13회. 실제 SV 시뮬레이션 아님.
- 반례 논리 검토: 대기 데이터 변경은 FAIL HOLD, 추가 거래는 FAIL EXTRA_ACCEPT 또는 ORDER, X/Z 전파 손실은 MONITOR_PORTS/expect_ports 불일치. 실제 변이 실행 미실행.
- SVG 단독 Chromium 렌더 및 스크린샷 확인, 텍스트 12개 겹침 0·viewBox 초과 0. 원격 SVG 552c98163f95a35166bfaff4a8baea6306c0f504와 로컬 렌더 원본 및 HTML 인라인 동일. 실제 신호선 도식으로 편집기 JSON은 미제작.
- 원격 HTML 6722eb2cf5409000f004309a009bd282b28e5926: 전체 RTL/TB/스크립트 원문 일치, 8절, 24장 탐색, INDEX 최신 링크, 중복 ID 없음, 시간 배분 제거 및 예상/실측 구분.

## 판정
- 원본·정적 비교, 독립 샘플 계산, SVG 단독 렌더 및 원격 파일 검증: PASS (각 범위).
- RTL_SIM(XSIM/Icarus) 및 실제 오류 주입: NOT_RUN — xvlog/xelab/xsim/iverilog/vvp 명령 없음.
- 전체 HTML·모바일·Pages 접속 및 편집기 JSON 왕복: NOT_RUN.
