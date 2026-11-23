# 제20장 · Factory·Config·Objection 검증 기록 v01

**과정:** 제5부 CHAPTER 20 · 60분 × 2교시  
**정상 GitHub 위치:** `Yuul-Jung/system_verilog_uvm_tb` 저장소 루트  
**학습안내서:** `ch20_factory_config_objection_v01.html`  
**DUT:** `reference_rtl/pwm_core.v` · Git Blob SHA `e813f3fb107bd327054d11e0b397817b8e7bd813` · 읽기 전용

## 점검표

| 항목 | 결과 | 근거 및 범위 |
|---|---|---|
| 제19장 이후 새 Chapter 20 | **PASS · 정적** | `course.json`에 20장, 총 편성 24장 유지 |
| 원본 PWM 무결성·13개 포트 | **PASS · 정적** | DUT Blob SHA 고정, 실제 7개 입력·6개 출력 포트 일치 |
| Factory 구현 교체 | **PASS · 정적** | 기본 `pwm20_driver`를 `pwm20_traced_driver`로 교체하도록 등록, `$cast` 점검 코드 |
| Factory 등록·생성 순서 | **PASS · 정적** | Test build_phase에서 override 등록 후 env 생성, Agent는 type_id::create() 사용 |
| Config DB 설정 전달 | **PASS · 정적** | Test에서 `env.*`에 `pwm20_cfg` 공유, Driver·Scoreboard에서 각각 get() |
| Sequence 설정 연동 | **PASS · 정적** | Sequence에는 `seq.cfg = settings`로 같은 계약 객체 핸들 전달 |
| Objection 수명주기 | **PASS · 정적** | raise → 세 거래 실행·카운트 확인 → drop 및 2000ns 전역 제한 |
| Monitor·Scoreboard 재사용 | **PASS · 정적** | REQUEST/APPLIED를 Analysis Port로 전달하고 별도 `duty_plan` 비교 |
| DUT 내부 계층 의존 없음 | **PASS · 정적** | 내부 counter/shadow 상태를 TB의 기대값으로 사용하지 않음 |
| 셸 실행 스크립트 안전성 | **PASS · 정적** | 파일·도구 검사, pipefail, 빌드·실행 로그, 결과/Trace 문자열 요구 |
| HTML 코드·도식 일치 | **PASS · 정적** | 10개 SECTION, 전체 소스·원본 RTL 전문, 중복 HTML id 없음 |
| INDEX 및 기존 20장 연결 | **PASS · 정적** | 모든 20개 장의 COURSE와 20개 INDEX 링크 동기화 |
| 좌측 PART→CHAPTER→SECTION | **PASS · DOM 모의 실행** | PART 05 한 개, CH17~20, 현재 CH20 아래 10개 절, 이전 CH19 |
| 개인정보·토큰 노출 | **PASS · 정적** | 공개 HTML의 로컬 절대경로·이메일·토큰 패턴 확인 |
| 실제 UVM 라이브러리 컴파일 | **NOT_RUN** | 현재 환경에 Verilator 실행기가 없음, UVM_HOME도 실측 미확인 |
| RTL 시뮬레이션·Factory Trace 확인 | **NOT_RUN** | 실행 파일·로그·파형 미생성 |
| Shell `bash -n` 문법 검증 | **NOT_RUN** | 실행 환경에서 스크립트 파일을 로컬로 실행하지 않음 |
| 브라우저 PC·모바일 실렌더링 | **NOT_RUN** | DOM 모의 실행과 실제 브라우저 조작은 구별 |
| GitHub Pages HTTP 공개 접속 | **NOT_RUN** | GitHub 소스 저장 확인과 Pages 공개 제공 검증은 별개 |

## 이 장에서 실제로 구현한 판정
- `pwm20_driver::type_id::set_type_override(pwm20_traced_driver::get_type())`로 구현 교체를 요청한다.
- `$cast(traced, env.ag.drv)`로 Factory에 의해 생성된 구체 타입을 확인한다.
- `uvm_config_db#(pwm20_cfg)`로 설정을 Driver와 Scoreboard에 공급한다.
- Test가 Objection을 올리고 듀티 2→6→0의 구동·관찰·적용이 각각 3회 완료되었는지 확인한 후 내린다.
- 정상 실행 시 기대하는 문자열은 `PASS CH20 factory=traced config=3 applied=3`이다. **실제 얻은 로그가 아니다.**

## Ubuntu 실행
```bash
# 1. 저장소 루트 이동
cd system_verilog_uvm_tb
# 2. 시뮬레이터 확인
verilator --version
# 3. 호환 UVM 라이브러리 경로 확인
test -f "$UVM_HOME/src/uvm_pkg.sv"
# 4. 원본 RTL과 제20장 TB 빌드·시뮬레이션
bash scripts/run_ch20.sh
```

시뮬레이터·UVM 버전, `.build/ch20/build.log`, `.build/ch20/simulation.log`, 실제 PASS/FAIL을 확보하기 전까지 **RTL_SIM=NOT_RUN**으로 유지한다. 동시 설정 요청·랜덤화·서로 다른 타입의 다중 Agent는 제20장 범위가 아니다.
