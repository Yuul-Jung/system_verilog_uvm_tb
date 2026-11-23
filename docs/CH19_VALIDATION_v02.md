# 제19장 · Monitor·Agent·Scoreboard 검증 기록 v02

**과정:** `system_verilog_uvm_tb` · 제5부 CHAPTER 19 · 1교시 60분 + 2교시 60분  
**정상 저장소:** `Yuul-Jung/system_verilog_uvm_tb` 최상위 루트  
**HTML:** `ch19_monitor_agent_scoreboard_v02.html`  
**원본 DUT:** `reference_rtl/pwm_core.v` · Blob SHA `e813f3fb107bd327054d11e0b397817b8e7bd813` (변경 없음)

## 범위 및 결과

| 검사 | 결과 | 확인 내용 |
|---|---|---|
| 원본 DUT / 포트 13개 | PASS(정적) | `pwm_core` 공개 7입력·6출력을 TB 인스턴스와 대조 |
| UVM 컴포넌트 분리 | PASS(정적) | `pwm19_sequence`, `pwm19_sequencer`, `pwm19_driver`, `pwm19_monitor`, `pwm19_agent`, `pwm19_scoreboard` |
| Agent와 Test 책임 | PASS(정적) | `pwm19_test`가 Sequence 생성·실행, `pwm19_agent`에는 Sequencer·Driver·Monitor |
| UVM Analysis 연결 | PASS(정적) | `ag.mon.ap.connect(sb.analysis_export)` 및 `write()` 구현 확인 |
| 입력과 관찰 시점 | PASS(논리 검토) | negedge에서 cfg_apply 변경, posedge 뒤 #1ns에서 Monitor 관찰 |
| 독립 기대값 | PASS(정적) | DUT 내부 계층 참조 없이 `planned_duty[3]` 2/6/0 대조 |
| 적용 타임아웃·순서 | PASS(논리 검토) | pending 해제, 요청·적용 개수, 최대 80ns 적용 시간 제한 |
| 동시 적용·동일 설정 반복 | 범위 제외 | 본 장은 순차 3개 서로 다른 듀티만 검증한다 |
| HTML 11절·실제 코드·도식 | PASS(정적) | 신호명 일치, Agent 밖의 Test/Sequence와 Agent 안의 Driver·Monitor 구분 |
| INDEX와 19개 장 파일 | PASS(정적) | 19개 GitHub 파일 확인·목차 정보 동기화, 6부 24장 과정 유지 |
| 좌측 PART→CHAPTER→SECTION | PASS(DOM 모의) | PART 05 1개·CH17/18/19·현재 CH19 아래 절 11개·이전 CH18·다음 INDEX |
| 실행 스크립트 구조 | PASS(정적) | Verilator/UVM_HOME 점검, 빌드 후 PASS 문자열·오류 검사 |
| SystemVerilog/UVM 컴파일 | **NOT_RUN** | 현재 제작 환경에 Verilator 및 UVM 라이브러리 없음 |
| PWM RTL 실제 실행·Scoreboard PASS | **NOT_RUN** | 실제 실행 로그나 VCD 미생성 |
| Bash `bash -n` 및 도구 실측 | **NOT_RUN** | 스크립트 정적 검토만 수행 |
| Chromium·모바일 실화면 | **NOT_RUN** | 시뮬레이션 DOM을 이용한 탐색 로직 검사와 실제 렌더링 시험 구별 |
| GitHub Pages HTTP 배포 | **NOT_RUN** | GitHub 소스 파일 존재와 공개 Pages 응답은 별개 |

## 예상 로그 (실제 출력 아님)

```text
UVM_INFO ... [SB] REQUEST 1 duty=2
UVM_INFO ... [SB] APPLIED 1 duty=2
UVM_INFO ... [SB] REQUEST 2 duty=6
UVM_INFO ... [SB] APPLIED 2 duty=6
UVM_INFO ... [SB] REQUEST 3 duty=0
UVM_INFO ... [SB] APPLIED 3 duty=0
UVM_INFO ... [RESULT] PASS CH19 requests=3 applied=3
```

## 실행 확인

```bash
cd system_verilog_uvm_tb
verilator --version
test -f "$UVM_HOME/src/uvm_pkg.sv"
bash scripts/run_ch19.sh
```

실제 Verilator/UVM 호환성이 검증되고 로그·파형을 확보하기 전에는 **RTL_SIM=NOT_RUN**으로 유지한다.
