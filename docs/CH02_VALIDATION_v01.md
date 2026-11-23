> 이전 기록: 이 문서는 `amd_soc_rtl/system_verilog_uvm_tb`에서 작성한 당시의 검증 기록을 옮긴 것입니다. 독립 저장소 이관 후의 새 검증 결과는 `docs/MIGRATION_v01.md`를 참조하세요. 실제 시뮬레이션 미실행 상태는 그대로 유지됩니다.

# 제02장 제작·검증 기록 v01
**과정:** `system_verilog_uvm_tb` · 제1부 제02장 · 60분 × 2교시  
**DUT 원본:** `part02_1/ch04/rtl/pwm_core.v` · Blob SHA `e813f3fb107bd327054d11e0b397817b8e7bd813`  
**참조 규칙:** `Yuul-Jung/rule_md` · `AGENTS.md`, `web/education-html/STANDARD.md`, `code/code-development-rules.md`, `common/code-style-rules.md`, `common/flowchart-rules.md`

| 점검 항목 | 판정 | 근거 |
|---|---|---|
| 원본 RTL 유지 | 통과(정적) | PWM RTL 읽기 전용 참조, 코드 수정 없음 |
| 13개 포트명 대조 | 통과(정적) | 원본·TB의 입력·출력 이름 1:1 확인 |
| 시간표·기대 출력 계산 | 통과(정적) | 10ns 클록, t35·t95·t125·t175·t190·t195 상태 분석 |
| HTML 섹션·중복 id·기존 디자인 | 통과(정적) | 페이지 9절, 교육용 공통 CSS·JS 사용 |
| INDEX·ch01·ch02 목차 연결 | 통과(정적) | 발행 2장만 링크, 다음/이전 탐색 소스 확인 |
| course.json·CURRICULUM·README 동기화 | 통과(정적) | 6부 24장 편성 유지, 발행 2장 표시 |
| 실제 Icarus 컴파일·vvp 실행 | NOT_RUN | 제작 환경에 iverilog 없음, apt DNS 실패 |
| VCD 파형 판독 | NOT_RUN | 생성된 실제 시뮬레이션 데이터 없음 |
| 실제 모바일·코드 복사 조작 | NOT_RUN | 실브라우저 동작 미검증 |
| GitHub Pages 배포 | NOT_RUN | 공개 URL·Pages 설정 미확인 |

## 예상 결과의 성격
다음은 실제 실행 결과가 아니라 RTL 논리와 TB 입력 시간에 따라 계산한 예상값이다.
- t=35ns 상승 에지: `pending=1`, `active_duty=0`
- t=95ns 상승 에지: `pending=0`, `active_duty=3`, `pwm_out=1`
- t=125ns 상승 에지: `pwm_out=0`
- t=175ns 상승 에지: `pwm_out=1`
- t=190ns 입력 LOW 리셋: `pwm_out=0` (조합 출력)
- t=195ns 상승 에지: `active_duty=0`, `active_enable=0` (순차 레지스터)

실제 PASS는 Ubuntu에서 `bash scripts/run_ch02.sh` 실행 후 로그·파형을 대조한 경우에만 기록한다.
