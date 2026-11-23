# CH10 경계조건·오류 주입 검증 기록 v02

**대상:** 제3부 CHAPTER 10 · 60분 × 2교시  
**독립 저장소:** `Yuul-Jung/system_verilog_uvm_tb` 루트  
**최신 HTML:** `ch10_corner_reset_timeout_v02.html`  
**DUT:** `reference_rtl/pwm_core.v` · Git Blob SHA `e813f3fb107bd327054d11e0b397817b8e7bd813` (수정 없음)

## 정적 및 실행 검증 구분

| 점검 | 결과 | 근거 |
|---|---|---|
| 원본 무결성 및 포트 | PASS(정적) | PWM 원본 Blob SHA 일치, DUT 7입력·6출력 원래 포트 이름과 대조 |
| 정상 경계조건 | PASS(정적) | 듀티 0%, 100%, 중간 리셋 뒤 재설정; 16표본×3묶음의 48회 검사 |
| 주기 경계·적용 기한 | PASS(정적) | `pending=0`과 `active_duty` 목표값을 함께 검사, 최대 10번 상승 에지 |
| 관찰값 오류 주입 | PASS(정적) | `+INJECT_FAULT`: DUT 출력을 변경하지 않고 `measured_pwm`만 반전 |
| 요청 누락 오류 주입 | PASS(정적) | `+INJECT_TIMEOUT`: 외부 `cfg_apply`만 생략하여 적용 기한 초과 유도 |
| 오류 감지 실패 방지 | PASS(정적) | 부정 시험에서 비정상 종료 코드와 전용 진단 문구를 모두 확인 |
| Shell 구문 | PASS(구문) | 실행 스크립트 본문을 `bash -n`으로 구문 검사 |
| HTML·INDEX·목차 | PASS(정적) | 10절, 중복 ID 없음, 제10장 v02 링크, PART→CHAPTER→SECTION 소스 유지 |
| RTL 컴파일·시뮬레이션 | **NOT_RUN** | 제작 환경에 `iverilog`·`vvp` 실행기 없음 |
| 실제 정상 PASS 및 오류 주입 검출 | **NOT_RUN** | 시뮬레이터 실행 로그 미생성 |
| VCD 파형·GTKWave 확인 | **NOT_RUN** | 실제 시뮬레이션 파형 미생성 |
| 실브라우저·모바일 확인 | **NOT_RUN** | 정적 HTML 검사와 실제 렌더링 검증은 별개 |
| GitHub Pages 공개 접속 | **NOT_RUN** | 웹 배포 페이지 실제 HTTP 접속 미검증 |

## 기대 출력 · 실제 실행 결과가 아님

- 정상 시험에서 `PASS CH10 requests=3 checks=48`을 출력하도록 구성.
- `+INJECT_FAULT`는 `$fatal` 및 `DETECTED_INJECTED_FAULT`를 출력하며 비정상 종료하도록 구성.
- `+INJECT_TIMEOUT`은 `$fatal` 및 `DETECTED_APPLY_TIMEOUT`을 출력하며 비정상 종료하도록 구성.
- 3개 실행을 모두 올바르게 검증한 셸 스크립트가 `PASS CH10 SUITE`를 출력하도록 구성.
- 오류 주입은 **DUT RTL 수정이 아니라 입력 또는 관찰 경로의 의도적 부정 시험**이다.

## Ubuntu에서 실제 검증

```bash
cd system_verilog_uvm_tb
iverilog -V
bash scripts/run_ch10.sh
```

실행 후 `.build/ch10/normal.log`, `fault_injection.log`, `apply_timeout.log`를 별도로 확인한다. 실행기·로그·파형이 확보되기 전에는 RTL_SIM=NOT_RUN을 유지한다.
