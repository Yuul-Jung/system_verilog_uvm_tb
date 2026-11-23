# 제09장 · 참조 모델·스코어보드 검증 기록 v02

**대상:** PART 03 · CHAPTER 09 · 2시간(1교시 60분 + 2교시 60분)  
**독립 저장소:** `Yuul-Jung/system_verilog_uvm_tb` 최상위 루트  
**재사용 DUT:** `reference_rtl/pwm_core.v` · Git Blob SHA `e813f3fb107bd327054d11e0b397817b8e7bd813`  
**HTML:** `ch09_reference_model_scoreboard_v02.html` (시간 로그 표시 형식 수정본)  

| 검사 항목 | 판정 | 실제 확인 범위 |
|---|---|---|
| 원본 PWM RTL 무결성 | 통과 · 정적 | 원본 Blob SHA 일치, 기존 DUT 수정 없음 |
| DUT 포트 13개 명칭 | 통과 · 정적 | 원본과 TB 직접 비교 |
| 참조 모델 독립성 | 통과 · 정적 | 모델에서 DUT 내부 state·hierarchical path 사용 없음 |
| 스코어보드 공개 출력 6개 | 통과 · 정적 | `!==`로 `pwm_out`·`pending`·`active_*` 비교 |
| 상태·경계·리셋 시간표 | 통과 · 논리 검토 | t30/95, t140/175, t250/255/335, t580/585, t610/675 확인 |
| 6가지 설정 시나리오 | 통과 · 정적 | duty 2,6,6 invert, disable, 8, reset 후 0 |
| 이벤트·타임아웃 | 통과 · 정적 | 하강 에지 입력 / 상승 에지 +1ns 비교 / 1200ns 종료 보호 |
| 시간 출력 안정성 | 통과 · 정적 | `$time`와 `%0d` 사용, `1ns/1ps` 시간 단위 |
| INDEX·course.json·HTML 구조 | 통과 · 정적 | CH09 v02 등록, 10절, 중복 id 없음 |
| 좌측 PART → CHAPTER → SECTION | 통과 · 정적 | 기존 CSS/JS 내 3계층 구성 코드 보존 |
| 시뮬레이터 실제 컴파일·실행 | **NOT_RUN** | 제작 환경에 `iverilog`/ `vvp` 실행기 없음 |
| RTL 파형·스코어보드 실제 PASS | **NOT_RUN** | RTL 시뮬레이션 실행 기록·VCD 미생성 |
| 실브라우저·모바일·코드 복사 동작 | **NOT_RUN** | 정적 HTML 구조 확인과 실브라우저 동작 검증 구별 |
| GitHub Pages HTTP 공개 접속 | **NOT_RUN** | 원격 GitHub 파일은 확인, 웹 배포 검증 별도 |

## 예상 결과 (실행 증거 아님)
- 시뮬레이션 종료가 t=720ns이면 매 상승 에지 뒤 출력 6개 묶음을 비교한 횟수는 이론상 72회.
- 설정 요청은 t=30/140/250/360/470/610ns에 발생.
- t=255ns `cfg_apply`가 주기 경계와 겹쳐도 극성 변경은 t=335ns에 적용되어야 함.
- t=580ns 리셋 LOW 인가 시 PWM 출력은 다음 상승 에지 전에 LOW가 되어야 함.
- 정상 종료 시 출력하도록 작성한 문자열은 `PASS CH09 score_cycles=72 scenarios=6`이나, **실제로 관측한 로그가 아님**.

## 실제 확인 절차
```bash
cd system_verilog_uvm_tb
iverilog -V
bash scripts/run_ch09.sh
```

실제 실행 결과가 나올 때까지 RTL_SIM=NOT_RUN이다. 기대값과 DUT가 동일한 결함을 공유하는 위험은 후속 경계값·SVA(시스템베릴로그 어설션) 검증으로 줄인다.
