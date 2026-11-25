# 제18장 v02 검증 기록

## 원본
- amd_soc_p2 04.2장 02절 Shadow/Active 및 06절 독립 PWM Core, p2_04_2_rtl_v02.html f42a821b9a35572d0940c24d6781bafb8287f21e.
- legacy/part02_1/ch04/rtl/pwm_core.v와 reference_rtl/pwm_core.v Blob e813f3fb107bd327054d11e0b397817b8e7bd813 동일. DUT 불변.

## 적대적 검토 및 수정
- 기존 3개 거래마다 경계 직후 한 출력만 검사하므로 PWM 중간 위상 오류를 놓칠 수 있음. 각 8개 표본의 활성 설정 4개·pending·출력 비교 및 대기 중 이전 활성 설정 보존 검사 추가.
- 직접 대입은 constraint를 검사하지 않는다. Driver에서 duty>8 거절, INVALID_DUTY 인자에서 두 번째 거래를 9로 변경. 정상 DUT 변경 없음. 전용 fatal은 첫 거래 완료 확인 completed=1을 포함.
- get_next_item과 item_done의 쌍 유지. 완료는 이 실습에서 전체 주기 검사를 끝낸 시점으로 정의. seq.start 반환 후 seq_finished, check_phase에서 3거래·24표본·실제 적용 순서 2/6/0, report_phase에서 UVM_ERROR/FATAL 누계 확인.
- get_next_item 호출은 finish_item 이전에 대기할 수 있음을 명시. Test가 초기 resetn을 제어하고 Driver는 설정 핀을 구동. config_db 경로는 uvm_test_top.env.drv. 독립 Monitor/Scoreboard는 다음 장에서 분리.
- AMD UG900 2026.1/2026.2의 독립 XSIM -L uvm 및 Accellera UVM 거래 인터페이스 참조. https://docs.amd.com/r/en-US/ug900-vivado-logic-simulation/Universal-Verification-Methodology-UVM-Support ; https://github.com/accellera-official/uvm-core/blob/main/src/tlm1/uvm_sqr_ifs.svh
- TB aa75a4526a22a282db7ad928521cf0a2511864b9, 실행 스크립트 f49e5afa48748055952e4ad1436d3e86408b13a2. XSIM 우선, 개별 로그 및 정상/부정 결과 확인.

## 독립 계산 (실제 RTL 실행 아님)
| duty | 요청 ns | 수락 ns | 반영 ns | 표본 ns | 예상 |
|---:|---:|---:|---:|---|---|
| 2 | 40 | 45 | 105 | 110~180 | 11000000 |
| 6 | 190 | 195 | 265 | 270~340 | 11111100 |
| 0 | 350 | 355 | 425 | 430~500 | 00000000 |
- 5/15/25ns 리셋, 30ns 해제. 시간 없는 거래 전달을 가정하고 8클록 경계와 하강 에지 대기를 독립 계산. 3개 거래, 24개 표본. 정확한 적용 시간 자체를 별도 assertion으로 강제하지 않으며 일관된 시간 이동 등의 결함은 놓칠 수 있다. 실제 UVM 스케줄러 및 변이 시험 미실행.
- 실제 스크립트와 동일 Blob 사본 bash -n 성공. 모의 도구 9/9: 정상, 부정 종료1, 부정 진단 누락, completed 오기, 부정 PASS, 부정 timeout, 정상 PASS 누락, 정상 UVM_ERROR=1, 정상 비정상 종료. 이는 모의 로그·종료 상태 판정 시험이지 UVM 실행 아님.
- 동일 Blob SVG 878a7e1e4a38d4ce6688e2d9961c336d3ee4da90 Chromium 단독 렌더/스크린샷 확인. 텍스트 24개, 겹침 0, 경계 초과 0. 도식 내 신호 및 클래스 명칭 확인.
- HTML 7b8b6ef76fe0ece84cf890e6bc48a426fe341d2b: RTL/TB/스크립트 전체 원문, 인라인 SVG, 8절, 24장 탐색·INDEX, 중복 ID 없음, 교시/대표 민감 패턴 제거 확인.

## 판정
- 원본 대조·독립 계산·Bash 문법 및 모의 판정·SVG 단독 렌더·원격 정적 검사 PASS(해당 범위).
- 실제 RTL_SIM/XSIM UVM 정상·부정 실행 NOT_RUN: 로컬 xvlog/iverilog/verilator 명령 부재. 실제 UVM 시간 및 오류 로그는 미확인.
- 전체 HTML·모바일·Pages 실접속·편집기 JSON 왕복 NOT_RUN. 호환 JSON 미제작.
