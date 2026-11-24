# 설계 학습안내서 ↔ 검증 학습안내서 24장 대응표

## 기준
- 주 설계 참조: `Yuul-Jung/amd_soc_npu`의 실제 발행 안내서. 이전 `amd_soc_rtl`은 원본 출처 추적용.
- 검증 과정은 기존 24장 순서를 유지한다. 설계 1개 장/절에 여러 검증 장이 대응할 수 있으며 강제로 1:1 장 번호를 맞추지 않는다.
- 아래 표는 원격 안내서의 실제 절 제목, 모듈 선언, 장별 실행 스크립트의 RTL 입력 파일을 확인한 결과다. 전체 RTL 시뮬레이션은 NOT_RUN. 개별 TB 계약과 실제 결과는 각 장 개정 시 별도 검증한다.
- EXACT_BLOB: 현행 설계 파일과 검증 스냅샷의 Git Blob SHA 동일. COMMENT_ONLY: SHA는 다르지만 주석 및 공백 제거 후 코드 문자열 동일하고 주석 제외 행 차이 없음(형식적 등가검증 아님). CONCEPT_ONLY: 관련 설계 개념만 대응, 동일 DUT 원본 경로 확인 못함. RTL_CHANGED: 실제 RTL 로직 차이 확인.

## 장별 매칭

| 검증 장 | 주제 | 현행 설계 안내서 장·절 | 실제 검증 DUT | 검증 초점 | 대응 상태 |
|---:|---|---|---|---|---|
| 01 | 테스트벤치의 첫 실행 | NPU 제1장 UART 계산기 · 03절 / 1-1 UART 에코 | `uart_echo_controller.v` | 입출력 관찰 | COMMENT_ONLY |
| 02 | Clock·Reset·이벤트 | 제2부 04.2장 RTL·AXI 풀이 · 06절 독립 PWM Core 전체 | `pwm_core.v` | 클록·리셋·경계 | EXACT_BLOB |
| 03 | 반복 자극과 작업 분리 | 제2부 04.2장 RTL·AXI 풀이 · 06절 독립 PWM Core 전체 | `pwm_core.v` | task/function 반복 | EXACT_BLOB |
| 04 | PASS/FAIL 자동 판정 | 제2부 04.2장 RTL·AXI 풀이 · 06절 독립 PWM Core 전체 | `pwm_core.v` | 기대값 자동 판정 | EXACT_BLOB |
| 05 | 검증 자료형과 타입 | NPU 제1장 UART 계산기 · 03절 / 1-1 UART 에코 | `uart_echo_controller.v` | 자료형·상태 | COMMENT_ONLY |
| 06 | 배열·큐·패키지 | NPU 제1장 UART 계산기 · 03절 / 1-1 UART 에코 | `uart_echo_controller.v` | 배열·queue·package | COMMENT_ONLY |
| 07 | 인터페이스·타이밍 분리 | NPU 제1장 UART 계산기 · 03절 / 1-1 UART 에코 | `uart_echo_controller.v` | interface/modport/clocking | COMMENT_ONLY |
| 08 | 객체와 제약 기반 입력 | NPU 제1장 UART 계산기 · 03절 / 1-1 UART 에코 | `uart_echo_controller.v` | class/constraint | COMMENT_ONLY |
| 09 | 참조 모델·스코어보드 | 제2부 04.2장 RTL·AXI 풀이 · 06절 독립 PWM Core 전체 | `pwm_core.v` | 독립 참조 모델 | EXACT_BLOB |
| 10 | 경계조건·오류 주입 | 제2부 04.2장 RTL·AXI 풀이 · 06절 독립 PWM Core 전체 | `pwm_core.v` | 경계·오류 주입 | EXACT_BLOB |
| 11 | 시간적 속성 검사 | 제2부 04.2장 RTL·AXI 풀이 · 06절 독립 PWM Core 전체 | `pwm_core.v` | SVA 시간 계약 | EXACT_BLOB |
| 12 | 기능 커버리지 | 제2부 04.2장 RTL·AXI 풀이 · 06절 독립 PWM Core 전체 | `pwm_core.v` | 기능 커버리지 | EXACT_BLOB |
| 13 | UART 스트림 검증 | NPU 제1장 UART 계산기 · 03절 / 1-1 UART 에코 | `uart_echo_controller.v` | 바이트 스트림·대기 | COMMENT_ONLY |
| 14 | FIFO 및 흐름 제어 | NPU 제1장 UART 계산기 · 03절 / 1-1 UART 에코 | `uart_core.v` + `uart_rx.v` + `uart_tx.v` | 실제 FIFO/PHY | COMMENT_ONLY |
| 15 | AXI4-Lite 레지스터 검증 | 제2부 04.2장 03~04절 및 10.3장 §2~3 (AXI/레지스터 개념), 03.2장 IRQ 참고 | `axi4lite_slave_adapter.v` + `custom_register_bank.v` | AW/W/B/AR/R·WSTRB | CONCEPT_ONLY |
| 16 | MAC·NPU 정수 연산 검증 | NPU 제1장 UART 계산기 · 04절 / 1-2 MAC 누산, 06절 / 1-4 MAC 파이프라인 | `mac_core.v` + `mac_pipeline_core.v` | 정수 곱·누산·지연 | EXACT_BLOB |
| 17 | 최소 UVM 환경 | 제2부 04.2장 RTL·AXI 풀이 · 06절 독립 PWM Core 전체 | `pwm_core.v` | UVM 최소 환경 | EXACT_BLOB |
| 18 | Sequence에서 Driver까지 | 제2부 04.2장 RTL·AXI 풀이 · 06절 독립 PWM Core 전체 | `pwm_core.v` | Sequence/Driver | EXACT_BLOB |
| 19 | Monitor·Agent·Scoreboard | 제2부 04.2장 RTL·AXI 풀이 · 06절 독립 PWM Core 전체 | `pwm_core.v` | Monitor/Scoreboard | EXACT_BLOB |
| 20 | Factory·Config·Objection | 제2부 04.2장 RTL·AXI 풀이 · 06절 독립 PWM Core 전체 | `pwm_core.v` | Factory/Config/Objection | EXACT_BLOB |
| 21 | UVM 레지스터 추상화 | 제2부 04.2장 03~04절 및 10.3장 §2~3 (AXI/레지스터 개념), 03.2장 IRQ 참고 | `axi4lite_slave_adapter.v` + `custom_register_bank.v` | RAL/Adapter/Predictor | CONCEPT_ONLY |
| 22 | 다중 Agent·VIP | 제2부 04.2장 03~04절 및 10.3장 §2~3 (AXI/레지스터 개념), 03.2장 IRQ 참고 | `axi4lite_slave_adapter.v` + `custom_register_bank.v` | AXI/Reset/IRQ 다중 Agent | CONCEPT_ONLY |
| 23 | NPU 통합 정답 비교 | NPU 제2장 4뉴런 NPU 보드 · 10절 / 2-8 통합 NPU Top; 제1장 05절 / 1-3 DSP 곱셈 | `npu_engine4.v` + `npu_dsp_mac_lane.v` + `dsp_multiplier.v` | 4뉴런 점수·완료 지연·argmax | RTL_CHANGED |
| 24 | 회귀·CI·검증 보고 | NPU 제1장 UART 계산기 · 03절 / 1-1 UART 에코 | `uart_echo_controller.v` | 시드 반복·회귀·CI | COMMENT_ONLY |

## 설계 페이지 근거 및 실제 RTL 경로
- **E**: NPU 제1장 UART 계산기 · 03절 / 1-1 UART 에코 — `p01_uart_calc_v01.html`. 실제 모듈 전체 확인. 주석 제외 코드 동일. UART PHY 통합 검증이 아님.
- **P**: 제2부 04.2장 RTL·AXI 풀이 · 06절 독립 PWM Core 전체 — `part02/p2_04_2_rtl_v02.html`. 원본 SHA 일치. PWM 단위 검증이며 AXI 래퍼나 보드 검증은 아님.
- **U**: NPU 제1장 UART 계산기 · 03절 / 1-1 UART 에코 — `p01_uart_calc_v01.html`. 3개 모듈 모두 주석 제외 코드 일치. FIFO·8N1 경로.
- **A**: 제2부 04.2장 03~04절 및 10.3장 §2~3 (AXI/레지스터 개념), 03.2장 IRQ 참고 — `part02/p2_04_2_rtl_v02.html` / `part02/p2_10_3_ip_library_v02.html` / `part02/p2_03_2_rtl_v02.html`. 설계 안내서의 RTL은 개별 IP 래퍼로 별개 모듈. 동일한 RMAP 원본의 현행 경로 미확인. 기존 스냅샷을 사용하고 직접 대응으로 표시하지 않음.
- **M**: NPU 제1장 UART 계산기 · 04절 / 1-2 MAC 누산, 06절 / 1-4 MAC 파이프라인 — `p01_uart_calc_v01.html`. 두 RTL SHA 일치.
- **N**: NPU 제2장 4뉴런 NPU 보드 · 10절 / 2-8 통합 NPU Top; 제1장 05절 / 1-3 DSP 곱셈 — `p02_npu4_board_v01.html` / `p01_uart_calc_v01.html`. engine4의 CMP1/CMP2 추가로 완료 시간 변경. 기존 TB의 지연 계약 재계산·재검증 필요. lane 주석 제외 동일, multiplier SHA 동일.

| 검증 RTL | amd_soc_npu 실제 파일 | 검증 스냅샷 SHA | 현행 설계 SHA |
|---|---|---|---|
| uart_echo_controller.v | common/rtl/uart_echo_controller.v | 28160c34522e47fbd961466651598da063bc74ae | 76269e771295fadcd0ddf160bee4556fdfa62e56 |
| pwm_core.v | part02/legacy/part02_1/ch04/rtl/pwm_core.v | e813f3fb107bd327054d11e0b397817b8e7bd813 | e813f3fb107bd327054d11e0b397817b8e7bd813 |
| uart_core.v | common/rtl/uart_core.v | 5390c312b186c27abb2b2818f76ec76d164c75f1 | 1572cda5d31ec8e26dc20a512e2606e6809669e0 |
| uart_rx.v | common/rtl/uart_rx.v | f0d2f9fcdf84aec913720103fb373738417bf7d1 | 70f3261694a8dec31f44e41cdad2ca511afdb778 |
| uart_tx.v | common/rtl/uart_tx.v | dfcb0cf10293a2a66ab7d704621a5219144673eb | 8b5fc5c391b6715f0ed04582a71953101c008c62 |
| mac_core.v | ch01/rtl/mac_core.v | d3f911b882f65e8f6096d76d31a2b710c18ae38d | d3f911b882f65e8f6096d76d31a2b710c18ae38d |
| mac_pipeline_core.v | ch03/rtl/mac_pipeline_core.v | f690b2db2a16626a43e0bb9f3c859d616e57116d | f690b2db2a16626a43e0bb9f3c859d616e57116d |
| axi4lite_slave_adapter.v | 동일 파일 경로 미확인 | eadaf8d3580023bed0c9b06f3e9b2a99de0cf266 | NOT_VERIFIED |
| custom_register_bank.v | 동일 파일 경로 미확인 | 49e5d0219574d1bcb9086dc99f259c191e35d82e | NOT_VERIFIED |
| npu_engine4.v | mini_npu/rtl/npu_engine4.v | 066218754ddfcc7807eff7333b308c207ab28175 | 62d66ff7a54d99734b0c3546b2d881ddf553a2ed |
| npu_dsp_mac_lane.v | mini_npu/rtl/npu_dsp_mac_lane.v | a9dae4662d2aaa82cb6ba629597650217d30e0d9 | cc673c0836e98dca47f95e7ecc638684c88f5f29 |
| dsp_multiplier.v | ch02/rtl/dsp_multiplier.v | 3dfb157f0e34dfb548fff7b3a6e5911ba664d504 | 3dfb157f0e34dfb548fff7b3a6e5911ba664d504 |

## 적대적 검증에서 발견한 핵심 사항
- 검증 13장도 실제 DUT는 `uart_echo_controller` 하나다. 14장의 UART FIFO/PHY와 혼동하지 않는다.
- 검증 11·12장의 실행 스크립트는 `tb/ch11/run_ch11.sh`, `tb/ch12/run_ch12.sh`에 존재한다. `scripts/` 공통 경로로 잘못 안내하지 않는다.
- 검증 24장의 Bash 스크립트는 `scripts/run_ch24.py`로 위임하며 실제 대상은 UART Echo 하나다. 과정 전체 자동 회귀라고 과장하지 않는다.
- 검증 15·21·22장의 RMAP 레지스터 은행과 현행 제2부 PWM/버튼 IP는 동일한 회로가 아니다. 원본 전체와 주소맵을 제공하며 설계 안내서는 개념 참고로만 명시한다. NPU AXI IP와도 혼동 금지.
- 검증 23장의 기존 엔진은 DRAIN2에서 argmax 결과와 완료 신호를 갱신하지만, 현행 엔진은 CMP1/CMP2를 거쳐 완료한다. 정상 연산 완료 시점이 2클록 늘어난 경로이므로 TB의 기대 지연·busy/done·경계조건을 새 소스로 다시 검토한다. 기존 스냅샷을 무단 덮어쓰지 않는다.
- 학생용 본문에는 실제 설계 과정명과 장·절, 필요한 파일명만 안내한다. 비공개 저장소 링크, SHA, 감사 이력은 배포 본문에 넣지 않는다. 공개 승인된 소스/의존 파일 및 전체 TB를 확보해야 실습이 독립적으로 가능하다.
- 각 장 개정 전 현재 설계 페이지와 RTL을 다시 읽고, 변경 시 이 표를 갱신한다. 실제 컴파일·시뮬레이션·렌더링 없이 PASS 판정 금지.

## 이번 검증 범위
- 24개 실행 경로와 주요 RTL 파일 목록 확인(11·12·24 특수 경로 포함).
- 현행 설계 안내서 6개 관련 페이지의 실제 절·모듈 확인, 12개 스냅샷 존재 확인, 현행 동일/변경 비교 10개 파일, 2개 현행 원본 경로 미확인.
- 실제 Vivado XSIM 실행, 24개 TB의 전수 동작 검증, 전체 페이지 렌더링: NOT_RUN.
