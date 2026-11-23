# RTL Testbench → SystemVerilog → UVM → 실무 검증 · 6부 24장
**기본 편성:** 총 48시간, 장별 2시간(60분 × 2), 신규 DUT 제작 최소화, 기존 RTL 검증.
**교육 순서:** 검증 문법 → 자동 판정 → SystemVerilog → Assertion·Coverage → 인터페이스 검증 → UVM → 실무.
**상태:** 제1~23장 발행 / 제24장 본문 미발행. 아래는 교육과정 편성안.

## 제1부 · Verilog 테스트벤치 기초
파형 확인에서 자동 판정까지

| 장 | 주제 | 핵심 문법·기술 | 기존 DUT 실습 |
|---|---|---|---|
| 01 | 테스트벤치의 첫 실행 | module·initial·timescale·$display·$finish | 기존 UART Echo RTL에 입력을 주고 출력 관찰 |
| 02 | Clock·Reset·이벤트 | always·#·posedge·negedge | PWM 클록·리셋과 시간 경계 |
| 03 | 반복 자극과 작업 분리 | task·function·repeat·for·wait | 기존 PWM 듀티 반복 입력·관찰 |
| 04 | PASS/FAIL 자동 판정 | if·===·$error·$fatal | 기대값과 DUT 출력 자동 비교 |

## 제2부 · SystemVerilog 문법
자료형·인터페이스·클래스 기초

| 장 | 주제 | 핵심 문법·기술 | 기존 DUT 실습 |
|---|---|---|---|
| 05 | 검증 자료형과 타입 | logic·bit·enum·struct·typedef | UART 상태·데이터 모델링 |
| 06 | 배열·큐·패키지 | packed/unpacked·queue·package | UART 기대 데이터 보관 |
| 07 | 인터페이스·타이밍 분리 | interface·modport·clocking block | 기존 UART Echo 6개 포트·Ready/Valid 검증 |
| 08 | 객체와 제약 기반 입력 | class·new·extends·rand·constraint | 거래 객체와 입력 범위 지정 |

## 제3부 · 자동 검증·속성·커버리지
검증을 계량하고 결함을 재현

| 장 | 주제 | 핵심 문법·기술 | 기존 DUT 실습 |
|---|---|---|---|
| 09 | 참조 모델·스코어보드 | reference model·scoreboard | 기존 PWM 출력 6개 매 클록 자동 비교 |
| 10 | 경계조건·오류 주입 | corner case·reset·timeout·negative test | PWM 0/100%, 중간 리셋, 관찰 오류·요청 누락 검출 |
| 11 | 시간적 속성 검사 | SVA·assert property·disable iff | Handshake와 FSM 규칙 |
| 12 | 기능 커버리지 | covergroup·coverpoint·bins·cross | PWM 설정 조합 기록 |

## 제4부 · 인터페이스·연산기 검증
실제 RTL을 그대로 재사용

| 장 | 주제 | 핵심 문법·기술 | 기존 DUT 실습 |
|---|---|---|---|
| 13 | UART 스트림 검증 | BFM·프레임·전송 오류 | UART Echo·Command |
| 14 | FIFO 및 흐름 제어 | full/empty·ready/valid·backpressure | UART FIFO |
| 15 | AXI4-Lite 레지스터 검증 | AW/W/B/AR/R·WSTRB | 기존 사용자 AXI IP |
| 16 | MAC·NPU 정수 연산 검증 | INT8·signed·pipeline·Python 모델 | MAC·BRAM·NPU Engine |

## 제5부 · UVM 검증 환경
재사용 가능한 Agent와 Environment

| 장 | 주제 | 핵심 문법·기술 | 기존 DUT 실습 |
|---|---|---|---|
| 17 | 최소 UVM 환경 | uvm_test·uvm_env·phase | PWM 최소 UVM 프로젝트 |
| 18 | Sequence에서 Driver까지 | sequence_item·sequence·sequencer·driver | 트랜잭션 구동 |
| 19 | Monitor·Agent·Scoreboard | analysis_port·analysis_imp·Agent | PWM 요청·반영 관찰 분리 및 독립 스코어보드 |
| 20 | Factory·Config·Objection | factory override·config_db·objection | PWM Driver 구현 교체·설정 공유·3거래 완료 확인 |

## 제6부 · 실무 회귀 검증
버스·시스템·지속 검증

| 장 | 주제 | 핵심 문법·기술 | 기존 DUT 실습 |
|---|---|---|---|
| 21 | UVM 레지스터 추상화 | RAL·adapter·predictor | AXI 레지스터 자동 검증 |
| 22 | 다중 Agent·VIP | virtual sequence·교육용 VIP-style | AXI Agent + Reset/IRQ Agent·W1C·독립 Monitor |
| 23 | NPU 통합 정답 비교 | 정수 모델·latency·corner case | NPU 입력·가중치·출력 검증 |
| 24 | 회귀·CI·검증 보고 | seed·regression·coverage·bug report | 자동 반복 검증 및 보고서 |

## 공통 운영
- 장별 1교시 60분(개념·구조·짧은 실습) + 2교시 60분(전체 코드·시뮬레이션·결과 해석).
- 합성 대상 RTL과 TB는 완전히 분리한다. 원본 RTL을 설명을 위해 고치지 않는다.
- 시뮬레이터 지원 기능과 실행 로그는 도구별로 확인한다.
- PASS/FAIL/NOT_RUN 판정, 실행 도구 버전, 원본 커밋·Blob SHA를 구분하여 기록한다.
- 각 장은 독립적으로 확인한 뒤 최신 HTML만 INDEX에 연결한다.
