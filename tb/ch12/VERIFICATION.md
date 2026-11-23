# 제12장 출처 및 검증 기록

- 발행 위치: Yuul-Jung/system_verilog_uvm_tb 저장소 루트
- 발행 장: 제12장 기능 커버리지, ch12_functional_coverage_v01.html
- DUT 읽기 전용: Yuul-Jung/amd_soc_rtl/part02_1/ch04/rtl/pwm_core.v
- DUT Blob SHA: e813f3fb107bd327054d11e0b397817b8e7bd813
- INDEX 발행 전 Blob SHA: f50a9ab8dc3bc8351f0ab5a0322c68a2b62b1daa
- course.json 발행 전 Blob SHA: b7ba44cb21524f190db96e2f43c8013cb0f941dd
- 발행 전 main HEAD: 1e6ac14a3461ce05b7e737d0cf2caa574124e79a
- 룰 정본: Yuul-Jung/rule_md AGENTS.md, web/education-html/STANDARD.md, code/code-development-rules.md, common/code-style-rules.md, common/flowchart-rules.md
- 포트·타이밍 계약: 7 입력 / 6 출력, cfg_apply 상승 에지 shadow 캡처, pending 표시, 주기 경계에서 활성 설정 갱신, resetn LOW 출력 즉시 차단
- 커버리지: 3 duty bins × 2 enable bins × 2 polarity bins, 12개 cross 조합
- DUT 원본 변경: 없음
- 정적 검토: 포트 이름 대조 PASS, HTML section id/링크/메뉴 구성 PASS, INDEX/course.json 갱신 대조 PASS, JS/CSS 원본 보존 PASS
- RTL 시뮬레이션: NOT_RUN (커넥터 환경에서 xrun 실행 불가)
- 브라우저 실제 렌더링: NOT_RUN
- 예상 출력은 실제 로그가 아님
