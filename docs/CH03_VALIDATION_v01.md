> 이전 기록: 이 문서는 `amd_soc_rtl/system_verilog_uvm_tb`에서 작성한 당시의 검증 기록을 옮긴 것입니다. 독립 저장소 이관 후의 새 검증 결과는 `docs/MIGRATION_v01.md`를 참조하세요. 실제 시뮬레이션 미실행 상태는 그대로 유지됩니다.

# 제03장 검증 기록 · v01

**과정:** `system_verilog_uvm_tb` · 제1부 제03장 · 1교시(60분) + 2교시(60분)  
**재사용 DUT:** `part02_1/ch04/rtl/pwm_core.v`  
**원본 Blob SHA:** `e813f3fb107bd327054d11e0b397817b8e7bd813`  
**규칙:** `Yuul-Jung/rule_md` 의 `AGENTS.md`, `web/education-html/STANDARD.md`, 코드·주석·구조도 표준 확인

| 점검 항목 | 판정 | 근거 |
|---|---|---|
| 중앙 `rule_md` 및 프로젝트 규칙 열람 | 통과 | 정본 5개 문서, 원본 저장소·과정 AGENTS 확인 |
| 기존 RTL 원본 보존 | 통과 | DUT는 읽기 전용 참조, `pwm_core.v` 변경 없음 |
| 원본 포트 대조 | 통과(정적) | `pwm_core` 13포트와 TB 13개 이름 대조 |
| `task`·`function`·`repeat`·`for`·`wait` 활용 | 통과(정적) | 제03장 TB 원문과 시간 흐름 검토 |
| 시간 계산 및 결과 예시 | 통과(논리 검토) | 초기 주기 8, 10ns 클록, t30/35/95/100~170의 흐름을 원본 조건과 대조 |
| HTML 구조·9개 절·고정된 공통 디자인 | 통과(정적) | 섹션 ID·코드 박스·SVG·CSS/JS 경로 점검 |
| INDEX·ch01~03 내비게이션 | 통과(정적) | 실제 발행 파일만 연결, `course.json v03` 반영 |
| 코드·도식의 DUT 신호명 일치 | 통과(정적) | `cfg_apply`, `cfg_duty`, `pending`, `active_duty`, `pwm_out` 확인 |
| 실제 RTL 컴파일 및 VVP 실행 | NOT_RUN | 제작 컨테이너에 `iverilog`, `vvp` 없음 |
| 실제 VCD 파형 확인 | NOT_RUN | 시뮬레이션을 실행하지 않아 파형 없음 |
| 실제 모바일·브라우저·복사 버튼 조작 | NOT_RUN | 실브라우저 실측 미실시 |
| GitHub Pages 외부 공개 | NOT_RUN | 실제 Pages URL 검증 전 |

## 예상 결과 (실측 아님)
- 첫 적용 t=95ns, 8개 출력 표본 t=100~170ns.
- 입력 듀티 0/2/4/6/8 → 각 주기의 HIGH 표본은 0/2/4/6/8회로 예상.
- `REQUEST` → `pending` HIGH → `pending` LOW → `APPLIED` → 8회 `SAMPLE` → `OBSERVED` 순으로 출력되도록 설계.
- 고정 시간 2000ns가 지나도 종료되지 않으면 교육용 TB가 `TIMEOUT`을 기록하고 종료한다. **아직 자동 PASS/FAIL 검증이 아니므로 관찰 완료를 통과로 표시하지 않는다.**

## 후속 검증 절차
Ubuntu에서 `bash scripts/run_ch03.sh`로 실제 시뮬레이션을 실행하고 도구 버전·원본 Blob SHA와 함께 로그/VCD를 보존한다. 실행 결과가 확보되기 전에는 `RTL_SIM=NOT_RUN`을 유지한다.
