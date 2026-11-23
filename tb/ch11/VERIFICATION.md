# 제11장 출처 및 검증 기록

- 발행 대상: Yuul-Jung/system_verilog_uvm_tb (루트)
- DUT: Yuul-Jung/amd_soc_rtl/part02_1/ch04/rtl/pwm_core.v (읽기 전용)
- DUT Blob SHA: e813f3fb107bd327054d11e0b397817b8e7bd813
- CURRICULUM.md Blob SHA (작성 시작): 0d05ac8613a0d420d37961ede626ac7840617a19
- RTL 계약: 13개 포트, clk 상승 에지 설정 캡처, 주기 경계에서 활성값 반영, resetn LOW일 때 조합 출력 차단, 레지스터 동기 초기화.
- SVA 샘플링: @(posedge clk), |-> 동일 샘플, |=> 다음 상승 에지 샘플.
- DUT 원본 수정: 없음
- 정적 검토: 코드 신호와 원본 포트명 대조 PASS; SVA 의미 검토 PASS; HTML/목차 링크는 발행 후 확인 필요
- RTL 시뮬레이션: NOT_RUN (현재 실행 환경에 xrun 없음)
- 브라우저 시각 검증: NOT_RUN
- 예상 출력은 실제 실행 로그가 아님.
