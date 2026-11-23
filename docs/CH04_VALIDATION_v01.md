> 이전 기록: 이 문서는 `amd_soc_rtl/system_verilog_uvm_tb`에서 작성한 당시의 검증 기록을 옮긴 것입니다. 독립 저장소 이관 후의 새 검증 결과는 `docs/MIGRATION_v01.md`를 참조하세요. 실제 시뮬레이션 미실행 상태는 그대로 유지됩니다.

# 제04장 검증 기록 v01

- DUT: `part02_1/ch04/rtl/pwm_core.v`, Blob SHA: `e813f3fb107bd327054d11e0b397817b8e7bd813`.
- 원본 RTL 변경 없음. 기존 13포트 이름으로 TB 연결.
- 신규 TB: `tb/ch04/tb_pwm_pass_fail.sv`.
- 실행: `scripts/run_ch04.sh`.
- HTML: `ch04_pass_fail_automation_v01.html`.
- 기준 규칙: `Yuul-Jung/rule_md`의 AGENTS·HTML STANDARD·코드 개발·스타일·구조도 규칙.
- 정적 검토: 9개 HTML 절, SVG 신호명, 코드 전체, CSS/JS 상대경로, 기존 모바일 메뉴·코드 복사 자산, 중복 ID, 예상 출력 표시.
- RTL_SIM: **NOT_RUN**. 실행 환경에 `iverilog`, `vvp`, `verilator` 없음.
- 실제 PASS/FAIL: **NOT_RUN**. 본문의 PASS는 정상 DUT를 가정한 예상 로그.
- 실제 브라우저·모바일 조작: **NOT_RUN**. 공통 CSS/JS 연결만 정적 점검.
- 검사 항목: 리셋 1 + Active 듀티 5 + HIGH 횟수 5 = 11.
- 후속: Ubuntu에서 `bash scripts/run_ch04.sh` 실행 후 로그·VCD·종료 코드를 검증할 것.
