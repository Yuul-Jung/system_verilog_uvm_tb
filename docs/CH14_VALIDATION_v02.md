# 제14장 v02 검증 기록

## 원본
- amd_soc_npu 제1장 UART 계산기 03절 서브젝트 1-1, p01_uart_calc_v01.html (f1089413362a271717b6a4b6a2e95deb569334f2).
- common/rtl/uart_core.v, uart_rx.v, uart_tx.v와 reference_rtl/의 파일을 주석·공백 제거 후 대조하여 동일 확인. 스냅샷 원본 불변.
- uart_core 5390c312b186c27abb2b2818f76ec76d164c75f1, uart_rx f0d2f9fcdf84aec913720103fb373738417bf7d1, uart_tx dfcb0cf10293a2a66ab7d704621a5219144673eb.

## 반례 및 수정
- 18개 송신만으로 full 발생을 주장할 수 없어 tx_stalls와 tx_full_swap 발생 확인. 공개 포트 수락/순서 독립 집계.
- 원본 uart_rx를 TX 정답 복조기에 그대로 사용하던 구조를 독립 시작/데이터/정지 표본 관찰기로 변경. 동일 설계 오류의 공유 가능성을 줄임. 18 프레임 이후 200클록 idle 검사.
- RX 전 구간 상승 에지에서 대기 중 valid/data 유지 확인. 16개 정상 배출과 별도 18개 수신 시험으로 16 FIFO+1 PHY 보류, 마지막 1개 유실·sticky overrun, full pop/push 및 17개 순서 검사.
- 빈 FIFO 리셋 대신 실제 RX 1개, TX FIFO 2개와 송신 진행 중 리셋. 리셋 선행 조건, 오류 플래그 초기화, 200클록 잔류 출력 확인.
- 100MHz 실제 TB 클록에 맞춰 CLK_HZ/BAUD를 100000000/10000000으로 변경. CPB=10은 유지. 100ns/bit, 1000ns/frame. 수신 framing error의 발생 경로와 임의 보레이트는 범위 밖.
- 조건부 VCD, 상대 RTL_DIR 절대화, 정확한 완료 행 확인, XSIM 우선 실행. TB 822a1cd2eb317cceffe7ca2004f8830ba7502833, 스크립트 ddc071375356669980c544e546713351afe391a5.

## 독립 거래 계산 (실제 HDL 실행 아님)
- 이상적인 클록별 큐 모델: TX 첫 수락 cycle 7, 첫 PHY 시작 cycle 8, 이후 101클록 간격. 18개 수락, 18개 송신, 대기 68클록, full 교체 1회. RX 18개 입력에서 17개 보존·1개 초과 유실, full 교체 1회, 순서 일치. 실제 수신 FSM 및 SV 이벤트 스케줄러 실행은 아님.
- 시작 에지 이후 첫 5개 하강 에지까지 45ns, D0~D7 145~845ns, stop 945ns. 표본은 비트 중앙 부근이며 모든 글리치 검출 아님.
- 원격 HTML e50f826a35dbf103d5fb85bd6e179dc1ef23b523, SVG 2c4b4c493bda1d5f9e0679b74cfa9927efe79b46. 3 RTL+TB+스크립트 전체 코드 일치, 8절, 24장 탐색 및 INDEX, 중복 ID 없음, 민감 패턴·교시 배분 제거 정적 검사 통과. SVG는 정적 구조 검토만 수행.
- 실제 XSIM/Icarus, 오류 변이, Bash 실실행, SVG/HTML 브라우저 렌더 및 모바일, Pages 실접속: NOT_RUN. 편집기 JSON 미제작. 실제 시뮬레이터 명령 부재. 
- 판정: 원본 대조·거래 모델 계산·원격 정적 검사 PASS. 실제 RTL 동작은 미검증. 
