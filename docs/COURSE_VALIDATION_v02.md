# 6부 24장 실제 실행·적대적 검증 v02

## 1. 판정 요약

- 실행일: 2026-11-26 KST.
- 기준 저장소: `Yuul-Jung/system_verilog_uvm_tb`, 시작 커밋 `c3ecb6b94499e346aeeb8cc0ff4da667f5aa676a`.
- 공통 규칙: `Yuul-Jung/rule_md` 커밋 `028248a19afc66e9aafdab393fbe0de10a3930ca`와 과정 `AGENTS.md`를 적용했다.
- 제01~24장을 번호 순서대로 실행했다. 최종 컴파일·elaboration·시뮬레이션은 24/24 완료했다.
- 제01~03장은 의도적으로 자동 PASS/FAIL이 없는 관찰 실습이므로 `EXECUTED_OBSERVATION`으로 구분한다. 제04~24장의 자동 판정은 모두 PASS다.
- 별도 부정 시험이 정의된 제10·11·17~22·24장은 기대한 전용 오류를 모두 검출했다. 정상 실행에 포함된 오류·거부 조건은 제13·14·15·16·23에서 확인했다.
- `reference_rtl/`은 작업 전후 Git diff가 0이며 원본 RTL은 변경하지 않았다.
- 로컬 로그·파형·커버리지·스크린샷은 `.build/`에 보존한다. 생성물은 Git에 커밋하지 않는다.

## 2. 검증 환경

| 항목 | 확인 결과 |
|---|---|
| Ubuntu | 현재 작업 환경에서 실행 |
| Vivado | `/tools/Xilinx/Vivado/2024.2`, Simulator 2024.2 |
| Vivado 설정 | 기존 `settings64.sh`를 source, 설치 파일 수정 없음 |
| Vivado 도구 | `xvlog`, `xelab`, `xsim`, `xcrg` 모두 확인 |
| Icarus Verilog | 12.0 stable |
| Verilator | 5.054, 저장소의 무시 대상 `.tools/` 아래 로컬 빌드 |
| 제약 해결기 | Z3 4.8.12, `.tools/` 아래 로컬 설치 |
| Python | 3.12.3 |
| 편집기 | VS Code 1.143.0, `.vscode/` 작업 설정 추가 |
| 브라우저 | Google Chrome headless, 로컬 HTTP 렌더링 |

`scripts/bootstrap_local_tools.sh`는 sudo 없이 `.tools/` 아래에 Verilator 5.054와 Z3를 설치하며 Vivado를 변경하지 않는다. `scripts/setup_env.sh`는 기존 Vivado 설정과 로컬 도구를 활성화하고 필수 명령을 검사한다.

## 3. 장별 실행 결과

`PASS_NEG`는 부정 시험이 실패해야 할 전용 이유로 종료했고 실행 스크립트가 이를 성공으로 판정했다는 뜻이다. `IN_RUN`은 별도 프로세스가 아니라 정상 회귀 안에서 오류 조건을 시험했다는 뜻이다.

| 장 | 최종 컴파일/Elab | 정상 시험 | 부정·오류 시험 | 실제 핵심 결과 | 주 로그 |
|---:|---|---|---|---|---|
| 01 | PASS | EXECUTED_OBSERVATION | NOT_RUN | 4개 ready/valid 상태 관찰 | `.build/ch01/output.log` |
| 02 | PASS | EXECUTED_OBSERVATION | NOT_RUN | reset·pending·active 경계 관찰 | `.build/ch02/output.log` |
| 03 | PASS | EXECUTED_OBSERVATION | NOT_RUN | duty 0/2/4/6/8 관찰 | `.build/ch03/output.log` |
| 04 | PASS | PASS | NOT_RUN | checks=11, errors=0 | `.build/ch04/output.log` |
| 05 | PASS | PASS | IN_RUN | checks=6, failures=0, 4상태 검사 | `.build/ch05/output.log` |
| 06 | PASS | PASS | IN_RUN | checks=11, failures=0, queue=0 | `.build/ch06/output.log` |
| 07 | PASS | PASS | IN_RUN | 4 cases checked, stall/accept | `.build/ch07/output.log` |
| 08 | PASS | PASS | NOT_RUN | 4 cases, 난수 2d/72 | `.build/ch08/output.log` |
| 09 | PASS | PASS | IN_RUN | score_cycles=72, scenarios=6 | `.build/ch09/output.log` |
| 10 | PASS | PASS | PASS_NEG ×2 | requests=3, checks=48; fault/timeout 검출 | `.build/ch10/*.log` |
| 11 | PASS | PASS | PASS_NEG | SVA checks=4; pending 위반 검출 | `.build/ch11/xsim/ch11*.log` |
| 12 | PASS | PASS | NOT_RUN | cases=12, functional coverage=100% | `.build/ch12/run.Iyw6Yi/` |
| 13 | PASS | PASS | IN_RUN | accepted=3, checks=14, X/Z·backpressure | `.build/ch13/simulation.log` |
| 14 | PASS | PASS | IN_RUN | tx=18, rx=16+17, overrun=1, reset=1 | `.build/ch14/simulation.log` |
| 15 | PASS | PASS | IN_RUN | commits=7, checks=18, WSTRB·RO | `.build/ch15/simulation.log` |
| 16 | PASS | PASS | IN_RUN | cycles=21, basic_valid=12, pipe_valid=10 | `.build/ch16/simulation.log` |
| 17 | PASS | PASS | PASS_NEG | checks=8; NOVIF 검출 | `.build/ch17/run.fdjMG1/` |
| 18 | PASS | PASS | PASS_NEG | checks=3, samples=24; INVALID_DUTY 검출 | `.build/ch18/run.m8Njsq/` |
| 19 | PASS | PASS | PASS_NEG | requests=3, applied=3, samples=24; SB_PWM 검출 | `.build/ch19/run.Ufk9kY/` |
| 20 | PASS | PASS ×2 | PASS_NEG ×3 | 두 계획 통과; FACTORY/NO_CFG/COUNTS 검출 | `.build/ch20/run.75rup7/` |
| 21 | PASS | PASS | PASS_NEG | RAL reads=7, writes=3; PREDICT_WRITE 검출 | `.build/ch21/run.uqAkWh/` |
| 22 | PASS | PASS | PASS_NEG | AXI_W=6, AXI_R=13, IRQ=4; IRQ_MISMATCH 검출 | `.build/ch22/run.bF30Mr/` |
| 23 | PASS | PASS | IN_RUN | cases=8, rejected=4 | `.build/ch23/simulation.log` |
| 24 | PASS | PASS ×3 | PASS_NEG | seeds 1/7/42, 비교기 오류 주입 검출 | `.build/ch24/run_1dofs29r/` |

제12장 `xcrg` HTML은 `.build/ch12/run.Iyw6Yi/report/functionalCoverageReport/dashboard.html`에 생성됐다. 제24장 기계 판독 보고서는 `.build/ch24/run_1dofs29r/report.json`이다.

## 4. 오류 분류와 최소 수정

| 단계 | 장 | 증상·원인 | 최소 조치 | 재실행 |
|---|---:|---|---|---|
| 컴파일 | 07 | Ubuntu 패키지 Verilator 5.020이 modport를 통한 clocking event wait를 지원하지 않음 | 원본·TB를 바꾸지 않고 로컬 Verilator 5.054 사용 | PASS |
| 컴파일 | 08 | `!randomize()`에 대한 WIDTHTRUNC 경고가 fatal 처리됨 | TB의 성공 판정을 `randomize() == 0`으로 명시 | PASS |
| 시뮬레이션 인프라 | 11 | 제한된 sandbox에서 XSIM child/IPC가 internal exception으로 종료 | 같은 빌드와 인자로 일반 로컬 실행 | 정상·부정 PASS |
| Elaboration | 17~22 | timescale이 없는 원본 RTL과 timescale이 있는 UVM TB 혼합 | 여섯 실행 스크립트에 `xelab -timescale 1ns/1ps` 추가 | 모두 PASS |
| 검증 | 전체 | 의도하지 않은 DUT/Scoreboard 불일치 | 없음 | 최종 미해결 0 |

의도적 부정 시험의 `UVM_FATAL`, `$fatal`, 비정상 종료는 검증 실패가 아니라 검출기 자체의 정상 동작이다. 정상 로그와 부정 로그를 별도 파일로 유지했다.

## 5. 교육자료 적대적 검증

### 소스·구조 일치

- `scripts/validate_course.py` 결과: 최신 HTML 24/24 존재, 장 번호 1~24 연속, `main`과 절 ID 연속, SVG role/접근성 이름, README·INDEX·공통 JS 최신 링크 모두 PASS.
- 24개 주 TB의 전체 본문을 HTML `<code>` 블록의 엔티티 해제 결과와 비교해 24/24 정확히 일치했다.
- 제08장과 제17~22장 새 버전은 실제 수정 코드와 실행 결과를 반영했다. 예상 출력 블록은 유지하고 2026-11-26 실측 블록을 별도로 표시했다.
- `course.json`을 v58로 올리고 README, INDEX, `assets/site.js`, 새 HTML의 내장 목차를 최신 파일명으로 동기화했다.
- 원본 RTL Git diff는 0이다. 구조도·타이밍도는 공개 포트와 TB 관찰 계약을 기준으로 재대조했으며, 이번 실행에서 구조도와 충돌하는 실제 신호명·카운트는 발견하지 못했다.

### 브라우저·시각 검사

- 로컬 HTTP에서 최신 24개 HTML을 Chrome 1920×1080으로 실제 로드하여 스크린샷 24개 생성에 성공했다.
- INDEX와 수정된 7개 장을 390×844로 추가 렌더링해 모바일 화면 8개를 생성했다.
- CH22의 실행 후 DOM에서 `course.json` 기반 `course-ch-link` 생성까지 확인했다.
- INDEX와 CH08의 데스크톱/모바일 이미지를 직접 표본 검사했다. 제목·본문·좌측/모바일 탐색과 가로 스크롤 도식은 표시됐다.
- 렌더링 증거: `.build/render/`의 32개 PNG.

## 6. 변경된 교육자료 버전

| 장 | 이전 | 최신 | 변경 이유 |
|---:|---|---|---|
| 08 | v02 | v03 | Verilator 호환 판정식과 실측 난수 결과 |
| 17 | v02 | v03 | 명시적 timescale과 XSIM 정상/부정 실측 |
| 18 | v02 | v03 | 명시적 timescale과 XSIM 정상/부정 실측 |
| 19 | v03 | v04 | 명시적 timescale과 XSIM 정상/부정 실측 |
| 20 | v02 | v03 | 명시적 timescale과 정상 2/부정 3 실측 |
| 21 | v02 | v03 | 명시적 timescale과 RAL 정상/부정 실측 |
| 22 | v03 | v04 | 명시적 timescale과 다중 Agent 정상/부정 실측 |

## 7. NOT_RUN·제한 사항

- GitHub Actions의 원격 CI 실행: `NOT_RUN`. 이 검증은 로컬 24장 전수 실행이며 제24장 워크플로를 원격에서 재실행하지 않았다.
- GitHub Pages 공개 URL의 배포 완료·HTTP 접근: `NOT_RUN`. 푸시 후 저장소 원격 커밋 일치만 별도로 확인한다.
- 32개 브라우저 스크린샷 전부에 대한 사람의 픽셀 단위 겹침 판독: `NOT_RUN`. Chrome 로드 32/32와 INDEX/CH08 표본 육안 검사는 완료했다.
- 별도 부정 모드가 설계되지 않은 장은 표에서 `NOT_RUN`으로 유지했다. 정상 회귀에 포함된 경계·오류 조건을 별도 부정 시험으로 과장하지 않았다.
- `.build/`와 `.tools/`는 각각 약 76MB와 2.4GB의 로컬 증거/도구이며 `.gitignore` 대상이다. 새 클론에서는 `bootstrap_local_tools.sh`로 도구를 재구성해야 한다.
