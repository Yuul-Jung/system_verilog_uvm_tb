# 제4부(13~16장) 종합 검증

| 장 | 검증 축 | 최신 발행 |
|---|---|---|
| 13 | 조합 UART Echo·독립 거래 모니터·4상태 전파 | ch13_uart_stream_verification_v02.html |
| 14 | 실제 UART PHY·16바이트 FIFO·흐름 제어 | ch14_fifo_flow_control_v02.html |
| 15 | AXI4-Lite 독립 채널·레지스터 계약 | ch15_axi4lite_register_verification_v02.html |
| 16 | INT8 정수 MAC·부호 확장·순환·파이프라인 | ch16_mac_npu_integer_verification_v02.html |

## 검토 결과
- 13장 조합 전달은 실제 저장소나 직렬 프레임 수신 검증이 아님. 14장에서 직렬 8N1 독립 복조 및 실제 FIFO full/push/pop, 16+1 RX 보존과 overrun, 비어 있지 않은 상태의 리셋으로 확장한다. 14장의 100MHz/10Mbps/CPB10은 가속 실습 조건이며 보드 기본 보레이트가 아니다. 실제 RX FSM·시뮬레이터 이벤트 및 모든 프레임 오류는 미검증.
- 15장 범용 어댑터와 레지스터 뱅크는 기존 스냅샷 유지. amd_soc_p2 설계 안내서 04.2장 03~04절, 10.3장 2~3절, 03.2장과 CONCEPT_ONLY이며 정확한 현행 원본 경로/동일성은 NOT_VERIFIED. PWM/IRQ 슬레이브와 OKAY/오류 응답 정책을 혼용하지 않는다. W1P·W1C 및 event 경합, 보호 속성과 전체 AXI 규격 시험은 후속 범위.
- 16장에서는 기존 오버플로 미발생, 부호 확장 미검증, 보류 곱 reset 폐기 미검증을 보완. 양·음 범위 초과와 16/24비트 비교, Python 실제 계산으로 확인. NPU 전체 추론 검증으로 과대 해석하지 않는다.
- 원본 파일 보존: 13/14장 UART 계열은 주석 제외 일치, 16장 두 MAC은 정확한 Blob 일치. 15장은 현행 설계 동일성 미확인. 4장에 배포된 RTL/TB/실행 파일 및 Python 원문 대조 완료. 마지막 주석과 탐색 변경 반영 확인.
- 13~15장의 구버전 탐색 경로 동기화 및 16장 이전 URL 리다이렉트. 네 장 각각 8절, 24장 탐색, INDEX 최신 링크, 중복 ID·시간 배분 및 대표 민감 패턴 없음 정적 확인. 공통 CSS/JS 변경 없음.
- 학습 순서: 신호 거래 → 실제 큐/PHY → 독립 버스 채널 → 수치 및 시간 비교. 이후 UVM의 거래·driver·monitor·scoreboard 구성 요소와 연결한다.

| 항목 | 판정 |
|---|---|
| 원본/스냅샷 보존·배포 소스 대조 | 완료 (4/4) |
| 현행 설계 동일성 | 13/14/16 확인, 15 CONCEPT_ONLY |
| 독립 계산 | 완료 (장별 범위) |
| 제16장 Python 실제 실행·Bash 문법 | PASS |
| 제13/16장 SVG 단독 렌더 | 장별 기록 확인 |
| 제14/15장 SVG 실제 렌더 | NOT_RUN |
| 24장 탐색 및 INDEX | PASS (정적) |
| 실제 RTL_SIM·변이 검증 | NOT_RUN |
| 전체 HTML·모바일·Pages 실접속·편집기 JSON | NOT_RUN |

최종 원격 HTML Blob:
- ch13_uart_stream_verification_v02.html: 0c4981c2b92f6ac3e529bafa6b1fb50216009957
- ch14_fifo_flow_control_v02.html: 60992142f6beb94abf2cfdc78b990c9b215a4ae8
- ch15_axi4lite_register_verification_v02.html: b42dcee3b57b2dbdff5c6f6c73408c23907c19fb
- ch16_mac_npu_integer_verification_v02.html: 7a0fe877dff4a67a342a66c9d950c6b0d991be22

제4부 개정 및 정적 종합 검증 완료. 실제 시뮬레이션과 15장 현행 원본 매칭은 미검증 상태로 유지한다. 다음 제17장 최소 UVM 환경.
